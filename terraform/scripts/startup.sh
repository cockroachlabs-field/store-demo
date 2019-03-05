#!/bin/bash

sudo timedatectl set-ntp no
sudo apt-get install ntp ntpstat
sudo service ntp stop
sudo ntpd -b time.google.com

sudo sed -i '/^pool/s/^/#/' /etc/ntp.conf
sudo sed -i '/^server/s/^/#/' /etc/ntp.conf

sudo tee -a /etc/ntp.conf <<EOL
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOL

sudo service ntp start

# Increase Limits
sudo tee -a /etc/security/limits.conf <<EOL
*              soft     nofile          66000
*              hard     nofile          66000
EOL