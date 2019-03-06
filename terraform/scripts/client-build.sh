#!/bin/bash

sudo apt-get update -yq
sudo apt-get install -yq openjdk-8-jdk git

sudo git clone https://github.com/cockroachlabs/store-demo.git

cd store-demo

sudo ./mvnw clean compile package -DskipTests

cp loader/target/*.jar ~/

cp runner/target/*.jar ~/