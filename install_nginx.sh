#!/bin/bash

# This is a basic script for installing NGINX on Ubuntu 22.04 containers.
# It uses the installation instructions from http://nginx.org/en/linux_packages.html and was converted to a script using ChatGPT

# Install the prerequisites
sudo apt -y install curl gnupg2 ca-certificates lsb-release ubuntu-keyring

# Import an official nginx signing key
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Verify that the downloaded file contains the proper key
output=$(gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg)

# The output should contain the full fingerprint 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
fingerprint="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"

if [[ $output != *"$fingerprint"* ]]; then
    echo "Error: key file doesn't match"
    exit 1
fi

# Prompt user to use Mainline package or not
echo -en "$(tput setaf 5)$(tput bold)Do you want to use stable package $(tput setaf 2)(choose Y unless you want Mainline)$(tput setaf 5) (y/n)?$(tput sgr0) "
read -r use_stable

# Set up the apt repository for stable/mainline nginx packages
if [[ "$use_stable" == "n" ]]; then
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
else
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
fi

# Set up repository pinning to prefer our packages over distribution-provided ones
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx

# To install nginx
sudo apt -y update
sudo apt -y install nginx

echo -e "$(tput setaf 5)$(tput bold)\nNGINX installation complete. You should now update your config file.\nBy default, the configuration file is named nginx.conf and placed in one of\n/usr/local/nginx/conf, /etc/nginx, or /usr/local/etc/nginx.\n$(tput sgr0)"
