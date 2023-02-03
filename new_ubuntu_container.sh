#!/bin/bash

# Prompt the user for a container name
read -p "Enter a container name: " container_name

# Validate the container name
if [ -z "$container_name" ]; then
  echo "Error: Container name cannot be empty."
  exit 1
fi

# Prompt the user for the number of CPUs
read -p "Enter the number of CPUs (1 or higher): " cpu_count

# Validate the CPU count
if ! [[ $cpu_count =~ ^[0-9]+$ ]] || [ "$cpu_count" -lt 1 ]; then
  echo "Error: Invalid number of CPUs. Please enter a number that is 1 or higher."
  exit 1
fi

# Prompt the user for the amount of RAM
read -p "Enter the amount of RAM in MB (128 or higher): " ram_size

# Validate the RAM size
if ! [[ $ram_size =~ ^[0-9]+$ ]] || [ "$ram_size" -lt 128 ]; then
  echo "Error: Invalid amount of RAM. Please enter a number that is 128 or higher."
  exit 1
fi

# Prompt the user for the amount of storage
read -p "Enter the amount of storage in GB (10 or higher): " storage_amount

# Validate the storage amount
if ! [[ $storage_amount =~ ^[0-9]+$ ]] || [ "$storage_amount" -lt 10 ]; then
  echo "Error: Invalid amount of storage. Please enter a number that is 10 or higher."
  exit 1
fi

# Prompt the user for the size of the swap file
read -p "Enter the size of the swap file in MB (0 or higher): " swap_size

# Validate the swap size
if ! [[ $swap_size =~ ^[0-9]+$ ]]; then
  echo "Error: Invalid size of swap file. Please enter a number that is 0 or higher."
  exit 1
fi

# Get a list of all valid storage locations
storage_locations=$(pvesm status --type dir | awk '{print $1}')

# Prompt the user to select a storage location
PS3="Select a storage location: "
select storage_location in $storage_locations; do
  if [ -n "$storage_location" ]; then
    break
  fi
done

# Check if the template file exists
template_file="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
if [ ! -f "$template_file" ]; then
  echo "Error: Template file not found."
  exit 1
fi

# Get the next available container number
container_number=$(pct list | tail -n +2 | awk '{print $1}' | sort -n | tail -n 1)
container_number=$((container_number + 1))

# Check if the container number is already in use
while pct list | grep -q "^$container_number"; do
  container_number=$((container_number + 1))
done

# Create the container with the specified parameters
pct create "$container_number" local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz \
    --name "$container_name" \
    --cpus "$cpu_count" \
    --memory "$ram_size" \
    --rootfs "$storage_location:$storage_amount" \
    --swap "$swap_size"

# Start the container
pct start "$container_number" &

# Show a message indicating that the script is waiting for the container to obtain an IP address
echo "Waiting for IP address via DHCP..."

# Keep trying to retrieve the container's IP address in the background until it succeeds
while true; do
  container_ip=$(pct exec "$container_number" bash -c "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1")
  if [ -n "$container_ip" ]; then
    break
  fi
  sleep 5
done

# Set up passwordless autologin for the root user
ssh-keygen -t rsa
ssh-copy-id root@"$container_ip"

# Ask the user if they want to start the container
read -p "Do you want to start the container now (yes/no)? " start_container

# If the user wants to start the container, start it
if [ "$start_container" == "yes" ]; then
  pct start "$container_number"
fi
