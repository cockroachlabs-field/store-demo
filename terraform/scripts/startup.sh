#!/bin/bash

while [[ ! -f /var/lib/cloud/instance/boot-finished ]]; do echo 'waiting for cloud-init...'; sleep 1; done

sudo apt-get update --fix-missing
sudo apt-get upgrade -y
sudo apt-get install -yqq ntp ntpstat

sudo timedatectl set-ntp no

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

sudo tee -a /etc/security/limits.conf <<EOL
*              soft     nofile          66000
*              hard     nofile          66000
EOL