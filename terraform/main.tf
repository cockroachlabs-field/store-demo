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

# SC
module "a" {
  name = "A"
  source = "./modules/azure"
  location = "eastus"
  lat = "32.784618"
  long = "-79.940918"

  crdb_version = var.crdb_version
  node_machine_type = var.azure_machine_type
  client_machine_type = var.azure_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.azure_private_key_path
  public_key_path = var.azure_public_key_path
  user = var.azure_user

  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}

# GA
module "b" {
  name = "B"
  source = "./modules/azure"
  location = "eastus"
  lat = "33.753746"
  long = "-84.386330"

  crdb_version = var.crdb_version
  node_machine_type = var.azure_machine_type
  client_machine_type = var.azure_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.azure_private_key_path
  public_key_path = var.azure_public_key_path
  user = var.azure_user

  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}

# IA
module "c" {
  name = "C"
  source = "./modules/gcp"
  region = "us-central1"
  zone = "us-central1-a"
  lat = "41.661129"
  long = "-91.530167"

  crdb_version = var.crdb_version
  credentials_file = var.gcp_credentials_file
  node_machine_type = var.gcp_machine_type
  client_machine_type = var.gcp_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.gcp_private_key_path
  user = var.gcp_user

  project_id = var.gcp_project_id
  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}

# MO
module "d" {
  name = "D"
  source = "./modules/gcp"
  region = "us-central1"
  zone = "us-central1-b"
  lat = "38.627003"
  long = "-90.199402"


  crdb_version = var.crdb_version
  credentials_file = var.gcp_credentials_file
  node_machine_type = var.gcp_machine_type
  client_machine_type = var.gcp_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.gcp_private_key_path
  user = var.gcp_user

  project_id = var.gcp_project_id
  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}

# CA
module "e" {
  name = "E"
  source = "./modules/gcp"
  region = "us-west2"
  zone = "us-west2-a"
  lat = "34.052235"
  long = "-118.243683"

  crdb_version = var.crdb_version
  credentials_file = var.gcp_credentials_file
  node_machine_type = var.gcp_machine_type
  client_machine_type = var.gcp_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.gcp_private_key_path
  user = var.gcp_user

  project_id = var.gcp_project_id
  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}

# AZ
module "f" {
  name = "F"
  source = "./modules/gcp"
  region = "us-west2"
  zone = "us-west2-b"
  lat = "33.4484"
  long = "-112.074036"

  crdb_version = var.crdb_version
  credentials_file = var.gcp_credentials_file
  node_machine_type = var.gcp_machine_type
  client_machine_type = var.gcp_machine_type_client
  os_disk_size = var.os_disk_size
  private_key_path = var.gcp_private_key_path
  user = var.gcp_user

  project_id = var.gcp_project_id
  cluster_name = local.cluster_name
  node_count = local.node_count
  client_count = local.client_count
  jdbc_port = local.jdbc_port
  sleep = local.sleep
}


# ---------------------------------------------------------------------------------------------------------------------
# start cluster nodes
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "start_trigger" {
  triggers = {
    a_public_ips = join(",", module.a.node_public_ips)
    b_public_ips = join(",", module.b.node_public_ips)
    c_public_ips = join(",", module.c.node_public_ips)
    d_public_ips = join(",", module.d.node_public_ips)
    e_public_ips = join(",", module.e.node_public_ips)
    f_public_ips = join(",", module.f.node_public_ips)
  }
}
resource "null_resource" "start_a_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_trigger"]

  connection {
    user = var.azure_user
    host = element(module.a.node_public_ips, count.index)
    private_key = file(var.azure_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.a.name} ${element(module.a.node_private_ips, count.index)} ${element(module.a.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}

resource "null_resource" "start_b_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_a_nodes"]

  connection {
    user = var.azure_user
    host = element(module.b.node_public_ips, count.index)
    private_key = file(var.azure_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.b.name} ${element(module.b.node_private_ips, count.index)} ${element(module.b.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_c_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_a_nodes"]

  connection {
    user = var.gcp_user
    host = element(module.c.node_public_ips, count.index)
    private_key = file(var.gcp_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.c.name} ${element(module.c.node_private_ips, count.index)} ${element(module.c.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_d_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_a_nodes"]

  connection {
    user = var.gcp_user
    host = element(module.d.node_public_ips, count.index)
    private_key = file(var.gcp_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.d.name} ${element(module.d.node_private_ips, count.index)} ${element(module.d.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_e_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_a_nodes"]

  connection {
    user = var.gcp_user
    host = element(module.e.node_public_ips, count.index)
    private_key = file(var.gcp_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.e.name} ${element(module.e.node_private_ips, count.index)} ${element(module.e.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${local.sleep}"]
  }

}


resource "null_resource" "start_f_nodes" {

  count = local.node_count

  depends_on = ["null_resource.start_a_nodes"]

  connection {
    user = var.gcp_user
    host = element(module.f.node_public_ips, count.index)
    private_key = file(var.gcp_private_key_path)
    timeout = "2m"
  }

  provisioner "file" {
    source = "${path.root}/scripts/node-start.sh"
    destination = "/tmp/node-start.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/node-start.sh",
      "/tmp/node-start.sh ${var.crdb_cache} ${var.crdb_max_sql_memory} ${module.f.name} ${element(module.f.node_private_ips, count.index)} ${element(module.f.node_public_ips, count.index)} ${join(",", module.a.node_public_ips)}"
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

  depends_on = [
    "null_resource.start_a_nodes",
    "null_resource.start_b_nodes",
    "null_resource.start_c_nodes",
    "null_resource.start_d_nodes",
    "null_resource.start_e_nodes",
    "null_resource.start_f_nodes"
  ]

  connection {
    user = var.azure_user
    host = element(module.a.node_public_ips, 0)
    private_key = file(var.azure_private_key_path)
    timeout = "2m"
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
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.a.name}', ${module.a.lat}, ${module.a.long});\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.b.name}', ${module.b.lat}, ${module.b.long});\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.c.name}', ${module.c.lat}, ${module.c.long});\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.d.name}', ${module.d.lat}, ${module.d.long});\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.e.name}', ${module.e.lat}, ${module.e.long});\"",
      "cockroach sql --insecure --database=${local.database_name} --execute=\"INSERT into system.locations VALUES ('region', '${module.f.name}', ${module.f.lat}, ${module.f.long});\""
    ]
  }

}