#!/bin/bash

sudo apt-get update --fix-missing
sudo apt-get install -yqq openjdk-8-jdk git

sudo git clone -q https://github.com/cockroachlabs/store-demo.git

cd store-demo

sudo ./mvnw -q clean compile package -DskipTests

cp loader/target/*.jar ~/

cp runner/target/*.jar ~/