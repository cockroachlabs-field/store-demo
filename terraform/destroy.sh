#!/bin/bash

export TF_LOG="INFO"
export TF_LOG_PATH="destroy.log"

terraform destroy -var-file="store-demo.tfvars" -auto-approve