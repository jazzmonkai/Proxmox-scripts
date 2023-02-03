#!/bin/bash

mkdir /etc/systemd/system/getty@tty1.service.d/

echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root %I $TERM" > /etc/systemd/system/getty@tty1.service.d/autologin.conf

systemctl edit container-getty@.service

echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 $TERM" > /etc/systemd/system/container-getty@.service

reboot
