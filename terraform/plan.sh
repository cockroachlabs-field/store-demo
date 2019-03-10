#!/bin/bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="plan.log"

rm -rf plan.out

terraform plan -var-file="store-demo.tfvars" -out=plan.out