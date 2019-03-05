#!/bin/bash

# Increase Limits
sudo tee -a /etc/security/limits.conf <<EOL
*              soft     nofile          66000
*              hard     nofile          66000
EOL