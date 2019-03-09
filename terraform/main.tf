locals {
  prefix = ""
  client_count = ""
  node_count = ""
  private_key_path=""

  sleep=""

  jdbc_port = ""
}

module "gcp_east" {
  source = "./modules/gcp"

  region = ""
  zone  = ""
  project = ""
  credentials_file = ""
  node_machine_type=""
  client_machine_type=""
  os_disk_size = ""


  prefix = "${local.prefix}"
  node_count = "${local.node_count}"
  client_count = "${local.client_count}"
  jdbc_port = "${local.jdbc_port}"
  private_key_path = "${local.private_key_path}"
  sleep="${local.sleep}"
}

module "azure" {

  source = "./modules/azure"
 location = ""


  prefix = "${local.prefix}"
  node_count = "${local.node_count}"
  client_count = "${local.client_count}"
  jdbc_port = "${local.jdbc_port}"
  private_key_path = "${local.private_key_path}"
  sleep="${local.sleep}"
}



# ---------------------------------------------------------------------------------------------------------------------
# init global cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "global_init_cluster" {

  depends_on = ["null_resource.azure_install_cluster"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_east, 0)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --insecure",
      "sleep ${var.provision_sleep}",
      "cockroach sql --insecure --execute=\"SET CLUSTER SETTING server.remote_debugging.mode = 'any';\"",
      "cockroach sql --insecure --execute=\"SET CLUSTER SETTING cluster.organization = '${var.crdb_license_org}';\"",
      "cockroach sql --insecure --execute=\"SET CLUSTER SETTING enterprise.license = '${var.crdb_license_key}';\"",
      "cockroach sql --insecure --execute=\"CREATE DATABASE store_demo;\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('country', 'us', 41.850033, -87.6500523);\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('cloud', 'gcp', 37.773972, -122.431297);\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('cloud', 'azure', 29.4167, -98.5);\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('region', 'east', 33.191333, -80.003999);\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('region', 'central', 29.4167, -98.5);\"",
      "cockroach sql --insecure --database=store_demo --execute=\"INSERT into system.locations VALUES ('region', 'west', 34.052235, -118.243683);\""
    ]
  }

}