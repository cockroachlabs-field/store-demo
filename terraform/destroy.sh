#!/bin/bash

export TF_LOG="WARN"
export TF_LOG_PATH="destroy.log"
export TF_WARN_OUTPUT_ERRORS=1

rm -rf destroy.log destroy.txt

terraform destroy -var-file="store-demo.tfvars" -auto-approve 2>&1 | tee destroy.txt