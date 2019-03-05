#!/bin/bash

sudo apt-get install -yq openjdk-8-jdk git

sudo git clone https://github.com/cockroachlabs/store-demo.git

cd store-demo

./mvnw clean package -DskipTests

cp loader/target/*.jar ~/

cp runner/target/*.jar ~/