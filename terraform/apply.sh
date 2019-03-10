#!/bin/bash

export TF_LOG="INFO"
export TF_LOG_PATH="apply.log"

terraform apply -var-file="store-demo.tfvars" -auto-approve