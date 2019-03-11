locals {
  cluster_name = "store-demo"
  database_name = "store_demo"

  node_count = "3"
  client_count = "1"

  sleep = "20"
  jdbc_port = "26257"

}

# ---------------------------------------------------------------------------------------------------------------------
# build clusters
# ---------------------------------------------------------------------------------------------------------------------

// gcp east1 - SC
// azure east2 - VA


// gcp central1 - IA

// gcp west2 - CA (los angeles)
// azure west2 - WA


module "gcp_east" {
  source = "./modules/gcp"
  region = "us-east1"
  zone = "us-east1-b"

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
  location = "eastus2"

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

module "gcp_central" {
  source = "./modules/gcp"
  region = "us-central1"
  zone = "us-central1-a"

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
  region = "us-west2"
  zone = "us-west2-b"

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

module "azure_west" {

  source = "./modules/azure"
  location = "westus2"

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

resource "null_resource" "start_trigger" {
  triggers = {
    gcp_east_public_ips = "${join(",", module.gcp_east.node_public_ips)}"
    azure_east_public_ips = "${join(",", module.azure_east.node_public_ips)}"
    gcp_west_public_ips = "${join(",", module.gcp_west.node_public_ips)}"
    azure_west_public_ips = "${join(",", module.azure_west.node_public_ips)}"
    gcp_central_public_ips = "${join(",", module.gcp_central.node_public_ips)}"
  }
}

resource "null_resource" "start_gcp_east_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_trigger"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_east.node_public_ips, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -fv cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=region=gcp-east --locality-advertise-addr=region=gcp-east@${element(module.gcp_east.node_private_ips, count.index)} --advertise-addr=${element(module.gcp_east.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_private_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}

resource "null_resource" "start_azure_east_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_gcp_east_nodes"]

  connection {
    user = "${var.azure_user}"
    host = "${element(module.azure_east.node_public_ips, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -fv cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=region=azure-east --locality-advertise-addr=region=azure-east@${element(module.azure_east.node_private_ips, count.index)} --advertise-addr=${element(module.azure_east.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_private_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}



resource "null_resource" "start_gcp_west_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_azure_east_nodes"]


  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_west.node_public_ips, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -fv cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=region=gcp-west --locality-advertise-addr=region=gcp-west@${element(module.gcp_west.node_private_ips, count.index)} --advertise-addr=${element(module.gcp_west.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}

resource "null_resource" "start_azure_west_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_gcp_west_nodes"]


  connection {
    user = "${var.azure_user}"
    host = "${element(module.azure_west.node_public_ips, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -fv cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=region=azure-west --locality-advertise-addr=region=azure-west@${element(module.azure_west.node_private_ips, count.index)} --advertise-addr=${element(module.azure_west.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_gcp_central_nodes" {

  count = "${local.node_count}"

  depends_on = ["null_resource.start_azure_west_nodes"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(module.gcp_central.node_public_ips, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -fv cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=region=gcp-central --locality-advertise-addr=region=gcp-central@${element(module.gcp_central.node_private_ips, count.index)} --advertise-addr=${element(module.gcp_central.node_public_ips, count.index)} --join=${join(",", module.gcp_east.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# init cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "init_cluster" {

  depends_on = ["null_resource.start_gcp_central_nodes"]

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
      "cockroach sql --insecure --execute=\"SET CLUSTER SETTING kv.allocator.load_based_lease_rebalancing.enabled = true;\"",
      "cockroach sql --insecure --execute=\"SET CLUSTER SETTING kv.allocator.load_based_rebalancing = 2;\"",
      "cockroach sql --insecure --execute=\"CREATE DATABASE ${local.database_name};\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', 'gcp-east', 33.191333, -80.003999);\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', 'azure-east', 33.191333, -80.003999);\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', 'gcp-central', 29.4167, -98.5);\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', 'gcp-west', 33.191333, -80.003999);\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', 'azure-west', 34.052235, -118.243683);\""
    ]
  }

}