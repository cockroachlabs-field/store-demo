locals {
  cluster_name = "store-demo"

  node_count = "3"
  client_count = "1"

  sleep = "20"
  jdbc_port = "26257"
}

# ---------------------------------------------------------------------------------------------------------------------
# build clusters
# ---------------------------------------------------------------------------------------------------------------------


module "gcp_east" {
  source = "./modules/gcp"

  region = "${var.gcp_east_region}"
  zone = "${var.gcp_east_zone}"
  credentials_file = "${var.gcp_credentials_file}"
  node_machine_type = "${var.gcp_machine_type}"
  client_machine_type = "${var.gcp_machine_type_client}"
  os_disk_size = "${var.os_disk_size}"
  private_key_path = "${var.gcp_private_key_path}"
  user = "${var.gcp_user}"

  project_id = "${var.gcp_project_id}"
  cluster_name = "${local.cluster_name}"
  node_count = "${local.node_count}"
  client_count = "${local.client_count}"
  jdbc_port = "${local.jdbc_port}"
  sleep = "${local.sleep}"
}

module "gcp_west" {
  source = "./modules/gcp"

  region = "${var.gcp_west_region}"
  zone = "${var.gcp_west_zone}"
  credentials_file = "${var.gcp_credentials_file}"
  node_machine_type = "${var.gcp_machine_type}"
  client_machine_type = "${var.gcp_machine_type_client}"
  os_disk_size = "${var.os_disk_size}"
  private_key_path = "${var.gcp_private_key_path}"
  user = "${var.gcp_user}"


  project_id = "${var.gcp_project_id}"
  cluster_name = "${local.cluster_name}"
  node_count = "${local.node_count}"
  client_count = "${local.client_count}"
  jdbc_port = "${local.jdbc_port}"
  sleep = "${local.sleep}"
}

module "azure_east" {

  source = "./modules/azure"

  location = "${var.azure_east_location}"
  node_machine_type = "${var.azure_machine_type}"
  client_machine_type = "${var.azure_machine_type_client}"
  os_disk_size = "${var.os_disk_size}"
  private_key_path = "${var.azure_private_key_path}"
  public_key_path = "${var.azure_public_key_path}"
  user = "${var.azure_user}"

  cluster_name = "${local.cluster_name}"
  node_count = "${local.node_count}"
  client_count = "${local.client_count}"
  jdbc_port = "${local.jdbc_port}"
  sleep = "${local.sleep}"
}


# ---------------------------------------------------------------------------------------------------------------------
# start cluster nodes
# ---------------------------------------------------------------------------------------------------------------------


resource "null_resource" "start_east_nodes" {

  count = "${local.node_count}"

  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_east.node_public_ips, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=east --locality-advertise-addr=region=east@${element(module.gcp_east.node_private_ips, count.index)} --advertise-addr=${element(module.gcp_east.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_private_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_west_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_east_nodes"]


  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_west.node_public_ips, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=west --locality-advertise-addr=region=west@${element(module.gcp_west.node_private_ips, count.index)} --advertise-addr=${element(module.gcp_west.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_azure_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_west_nodes"]

  connection {
    user = "${var.azure_user}"
    host = "${element(module.azure_east.node_public_ips, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=azure,region=central --locality-advertise-addr=region=central@${element(module.azure_east.node_private_ips, count.index)} --advertise-addr=${element(module.azure_east.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# init global cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "global_init_cluster" {

  depends_on = ["null_resource.start_azure_nodes"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_east.node_public_ips, 0)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --insecure",
      "sleep ${local.sleep}",
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