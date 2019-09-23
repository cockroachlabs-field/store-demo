# Store Demo - Terraform

Terraform is used to provision a 18 node CockroachDB cluster across 3 geographically disperse US Data Centers and 2 cloud providers.  Again, the intent is to demonstrate survivability across Data Centers, Cloud Providers and the Continental U.S. [power transmission grid](https://en.wikipedia.org/wiki/Continental_U.S._power_transmission_grid).
* Data Center A - Azure's `eastus` region, zone `1` in Virginia on the Eastern Interconnection grid
* Data Center B - Azure's `eastus` region, zone `2` in Virginia on the Eastern Interconnection grid
* Data Center C - Google's `us-central1` region, zone `us-central1-a` in Iowa on the Eastern Interconnection grid
* Data Center D - Google's `us-central1` region, zone `us-central1-b` in Iowa on the Eastern Interconnection grid
* Data Center E - Google's `us-west2` region, zone `us-west2-a` in California on the Western Interconnection grid
* Data Center F - Google's `us-west2` region, zone `us-west2-b` in California on the Western Interconnection grid
 
## Prerequisites
All of my development was done on a Mac running macOS Mohave.  Your mileage may vary on other platforms.  You will need to download and install the following.  For Google and Azure you will need an account and credentials.
* Terraform - https://www.terraform.io/downloads.html
* Google Cloud SDK - https://cloud.google.com/sdk/docs/quickstart-macos
* Azure CLI - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest

## Building the Cluster
1) Create a Google Cloud [Service Account Key](https://cloud.google.com/docs/authentication/getting-started) and download it as a `.json` file called `gcp-account.json` and place it in this directory.

2) Create a file called `store-demo.tfvars` and place it in this directory.  Contents of the file must include the following required variables with values appropriate for your environment.  For additional configuration options see [variables.tf](variables.tf).
    ```hcl-terraform
    gcp_project_id = "your google project id"
    gcp_user = "user used to ssh into google instances"
    azure_user = "user used to ssh into azure instances"
    crdb_license_org = "crdb license org"
    crdb_license_key = "crdb license key"
    ```
3) Initialize Terraform
    ```bash
    terraform init -upgrade
    ```

4) Build the cluster
    ```bash
    ./apply.sh
    ```

    If everything is successful you should see a message like this in the console...
    ```text
    Apply complete! Resources: 146 added, 0 changed, 0 destroyed.
    ```
5) Pick one of the public IP's listed above and visit the CockroachDB UI, `http://PICK_PUBLIC_IP_FROM_ABOVE:8080`


6) Destroy the cluster when you are finished
    ```bash
    ./destroy.sh
    ```
   
   If everything is successful you should see a message like this in the console...
   ```text
   Destroy complete! Resources: 146 destroyed.
   ```

## Other Helpful Commands

### Refresh State
```bash
./refresh.sh
```

### View Plan
```bash
./plan.sh
```

