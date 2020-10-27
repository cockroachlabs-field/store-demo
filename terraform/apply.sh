#!/bin/bash

export TF_LOG="WARN"
export TF_LOG_PATH="apply.log"
export TF_WARN_OUTPUT_ERRORS=1

rm -rf apply.log apply.txt

terraform apply -var-file="store-demo.tfvars" -auto-approve 2>&1 | tee apply.txt