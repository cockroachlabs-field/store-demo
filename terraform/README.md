# Store Demo - Terraform

Terraform is used here to provision a 9 node CockroachDB cluster across 3 geographically disperse US Data Centers and 2 cloud providers.  The intent is to demonstrate survivability across, Data Centers, Cloud Providers and the Continental U.S. [power transmission grid](https://en.wikipedia.org/wiki/Continental_U.S._power_transmission_grid).
* Data Center 1 - Google's `us-east1` region in Virgina on the Eastern Interconnection grid
* Data Center 2 - Microsoft's `southcentralus` region in Texas on the Texas Interconnection grid
* Data Center 3 - Google's `us-west2` region in southern California on the Western Interconnection grid

## Default Cluster Specifications
todo
 
## Prerequisites
All of my development was done on a Mac running macOS Mohave.  Your mileage may vary on other platforms.  You will need to download and install the following.  For Google and Azure you will need an account and credentials.
* Terraform - https://www.terraform.io/downloads.html
* Google Cloud SDK - https://cloud.google.com/sdk/docs/quickstart-macos
* Azure CLI - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest

## Building the Cluster
1) Create a Google Cloud [Service Account Key](https://cloud.google.com/docs/authentication/getting-started) and download it as a `.json` file called `gcp-account.json` and place it in this directory.

2) Create a file called `store-demo.tfvars` and place it in this directory.  Contents of the file must include the following required variables with values appropriate for your environment.  For additional configuration options see [variables.tf](variables.tf)
```hcl-terraform
gcp_project_name = "your gcp project name"
gcp_user = "your gcp username"
crdb_license_org = "your license org name"
crdb_license_key = "your license key"
```
3) Initialize Terraform
```bash
terraform init -upgrade
```

4) Build the cluster
```bash
terraform apply -var-file="store-demo.tfvars" -auto-approve
```

If everything is successful you should see a message like this in the console.
```text
Apply complete! Resources: 47 added, 0 changed, 0 destroyed.

Outputs:

azure_cockroach_public_ips = 23.102.157.43,104.214.25.95,104.214.34.67
google_cockroach_public_ips_east = 34.73.111.61,34.73.192.47,34.73.214.9
google_cockroach_public_ips_west = 35.235.108.56,35.235.73.122,35.236.3.98
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

