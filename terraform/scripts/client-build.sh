#!/bin/bash

sudo apt-get update --fix-missing
sudo apt-get install -yqq git wget apt-transport-https gnupg
sudo wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
sudo echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

sudo apt-get update --fix-missing
sudo apt-get install -yqq temurin-19-jdk

sudo git clone -q https://github.com/cockroachlabs/store-demo.git

cd store-demo

sudo git checkout -f master

sudo ./mvnw -q clean compile package -DskipTests

cp loader/target/*.jar ~/

cp runner/target/*.jar ~/