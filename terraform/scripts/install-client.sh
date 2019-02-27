#!/bin/bash

cat > /etc/ntp.conf << EOL
server metadata.google.internal iburst
EOL

sudo service ntp reload

sudo apt-get update
sudo apt-get install -yq default-jdk git