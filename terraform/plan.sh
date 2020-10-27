#!/bin/bash

export TF_LOG="WARN"
export TF_LOG_PATH="plan.log"
export TF_WARN_OUTPUT_ERRORS=1

rm -rf plan.log plan.txt

terraform plan -var-file="store-demo.tfvars" 2>&1 | tee plan.txt