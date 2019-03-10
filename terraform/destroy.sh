#!/bin/bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="destroy.log"

rm -rf destroy.log destroy.out

terraform destroy -var-file="store-demo.tfvars" -auto-approve 2>&1 | tee destroy.out