#!/bin/bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="apply.log"

rm -rf apply.log apply.out

terraform apply -var-file="store-demo.tfvars" -auto-approve 2>&1 | tee apply.out