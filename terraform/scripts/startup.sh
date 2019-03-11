#!/bin/bash

while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done

echo "install npt"
sudo apt-get update --fix-missing
sudo apt-get upgrade -y
sudo apt-get install -yqq ntp ntpstat

echo "disable timedatectl"
sudo timedatectl set-ntp no

echo "stop ntp"
sudo service ntp stop

echo "calling ntpd -b"
sudo ntpd -b time.google.com

echo "sed on ntp.conf"
sudo sed -i '/^pool/s/^/#/' /etc/ntp.conf
sudo sed -i '/^server/s/^/#/' /etc/ntp.conf

echo "append to ntp.conf"
sudo tee -a /etc/ntp.conf <<EOL
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOL

echo "start ntp"
sudo service ntp start

echo "increase limits"
sudo tee -a /etc/security/limits.conf <<EOL
*              soft     nofile          66000
*              hard     nofile          66000
EOL