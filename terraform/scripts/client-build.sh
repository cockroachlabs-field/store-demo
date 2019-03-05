#!/bin/bash

sudo apt-get install -yq openjdk-8-jdk git

sudo git clone https://github.com/cockroachlabs/store-demo.git

sudo cd store-demo

sudo ./mvnw clean compile package -DskipTests

sudo cp loader/target/*.jar ~/

sudo cp runner/target/*.jar ~/