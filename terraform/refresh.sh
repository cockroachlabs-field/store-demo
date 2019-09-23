#!/bin/bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="refresh.log"
export TF_WARN_OUTPUT_ERRORS=1

rm -rf refresh.log refresh.txt

terraform refresh -var-file="store-demo.tfvars" 2>&1 | tee refresh.txt