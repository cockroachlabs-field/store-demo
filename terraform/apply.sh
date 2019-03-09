#!/bin/bash

TF_LOG="INFO"
TF_LOG_PATH="apply.log"

terraform apply -var-file="store-demo.tfvars" -auto-approve