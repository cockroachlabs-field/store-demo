# Store Demo - Terraform

## Prerequisites
All of my development was done on a Mac running macOS Mohave.  Mileage may vary on other platforms.  You will need to download and install the following.  For Google and Azure you will need an account and credential.
* Terraform - https://www.terraform.io/downloads.html
* Google Cloud SDK - https://cloud.google.com/sdk/docs/quickstart-macos
* Azure CLI - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest
you

## Building the Cluster
1) create Google Cloud Service Account Key (https://cloud.google.com/docs/authentication/getting-started) and download it as a `.json` file called `gcp-account.json` and place it in this directory.

2) create a file called `store-demo.tfvars` and place it in this directory.  Contents of the file must include the following required variables with values appropriate for your environment.
```hcl-terraform
gcp_project_name = "your gcp project name"
gcp_user="your gcp username"
crdb_license_org="your license org name"
crdb_license_key="your license key"
```
3) initialize Terraform
```bash
terraform init -upgrade
```

4) build the cluster
```bash
terraform apply -var-file="store-demo.tfvars" -auto-approve
```

## Other Helpful Commands

### Refresh State
```bash
terraform refresh -var-file="store-demo.tfvars"
```

### View Plan
```bash
terraform plan -var-file="store-demo.tfvars"
```

### Destroy Cluster
```bash
terraform destroy -var-file="store-demo.tfvars" -auto-approve
```

