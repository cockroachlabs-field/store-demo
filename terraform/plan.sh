#!/bin/bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="plan.log"

rm -rf plan.log plan.out

terraform plan -var-file="store-demo.tfvars" 2>&1 | tee plan.out