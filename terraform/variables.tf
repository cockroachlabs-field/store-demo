# ---------------------------------------------------------------------------------------------------------------------
# required
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project_name" {
  description = "your google project name"
}

variable "gcp_user" {
  description = "user used to ssh into google instances"
}

variable "crdb_license_org" {
  description = "crdb license org"
}

variable "crdb_license_key" {
  description = "crdb license key"
}

# ---------------------------------------------------------------------------------------------------------------------
# optional
# ---------------------------------------------------------------------------------------------------------------------

variable "region_node_count" {
  default = 1
}

variable "storage_disk_size" {
  default = 375
}

variable "azure_storage_disk_size" {
  default = 2048
}

variable "os_disk_size" {
  default = 100
}

variable "gcp_east_region" {
  default = "us-east1"
}

variable "gcp_east_zone" {
  default = "us-east1-b"
}

variable "gcp_west_region" {
  default = "us-west2"
}

variable "gcp_west_zone" {
  default = "us-west2-b"
}

variable "gcp_machine_type" {
  default = "n1-standard-16"
}

variable "gcp_machine_type_client" {
  default = "n1-standard-8"
}

variable "gcp_private_key_path" {
  default = "~/.ssh/google_compute_engine"
}

variable "gcp_credentials_file" {
  default = "gcp-account.json"
}

variable "azure_machine_type" {
  default = "Standard_L16s_v2"
}

variable "azure_machine_type_client" {
  default = "Standard_L8s_v2"
}

variable "azure_private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "azure_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "azure_user" {
  default = "azureuser"
}

variable "crdb_version" {
  default = "v2.1.5"
}

variable "crdb_max_sql_memory" {
  default = ".25"
}

variable "crdb_cache" {
  default = ".25"
}

variable "provision_sleep" {
  default = "20"
}