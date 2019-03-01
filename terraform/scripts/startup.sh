#!/bin/bash

# Update & Patch Instance
sudo apt-get update --fix-missing

# Sync Clocks
cat > /etc/ntp.conf << EOL
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOL

sudo service ntp reload

# Increase Limits
sudo tee -a /etc/security/limits.conf <<EOL
*              soft     nofile          66000
*              hard     nofile          66000
EOL