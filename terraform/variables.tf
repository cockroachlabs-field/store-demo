# ---------------------------------------------------------------------------------------------------------------------
# required
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "your google project id"
}

variable "gcp_user" {
  description = "user used to ssh into google instances"
}

variable "azure_user" {
  description = "user used to ssh into azure instances"
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

variable "os_disk_size" {
  default = 100
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
  default = "Standard_F16s_v2"
}

variable "azure_machine_type_client" {
  default = "Standard_F8s_v2"
}

variable "azure_private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "azure_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "crdb_max_sql_memory" {
  default = ".25"
}

variable "crdb_cache" {
  default = ".25"
}

variable "crdb_nodes_per_region" {
  default = "3"
}
