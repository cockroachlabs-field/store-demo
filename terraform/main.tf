# ---------------------------------------------------------------------------------------------------------------------
# setup gcp providers
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

provider "google" {
  alias = "east"
  region = "us-east1"
  zone = "us-east1-b"
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

provider "google" {
  alias = "west"
  region = "us-west2"
  zone = "us-west2-b"
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# setup azure provider
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
}

# ---------------------------------------------------------------------------------------------------------------------
# provision gcp resources
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "sd_compute_network" {
  name = "crdb-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "sd_sql" {
  name = "allow-crdb-sql"
  network = "${google_compute_network.sd_compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["26257"]
  }
}

resource "google_compute_firewall" "sd_ui" {
  name = "allow-crdb-ui"
  network = "${google_compute_network.sd_compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["8080"]
  }
}

resource "google_compute_firewall" "sd_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.sd_compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_instance" "sd_east_cockroach_node" {

  count = "${var.region_node_count}"

  name = "crdb-gcp-east-${count.index}"
  machine_type = "${var.gcp_machine_type}"
  min_cpu_platform = "Intel Skylake"
  provider = "google.east"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  // for crdb data
  scratch_disk {
    interface = "NVME"
  }

  metadata_startup_script = "${file("${path.module}/scripts/startup.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "sd_east_client" {

  name = "crdb-gcp-east-client"
  machine_type = "n1-standard-4"
  provider = "google.east"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  // for client binary
  scratch_disk {
    interface = "NVME"
  }

  metadata_startup_script = "${file("${path.module}/scripts/startup.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "sd_west_cockroach_node" {

  count = "${var.region_node_count}"

  name = "crdb-gcp-west-${count.index}"
  machine_type = "${var.gcp_machine_type}"
  min_cpu_platform = "Intel Skylake"
  provider = "google.west"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  // for crdb data
  scratch_disk {
    interface = "NVME"
  }

  metadata_startup_script = "${file("${path.module}/scripts/startup.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "sd_west_client" {

  name = "crdb-gcp-west-client"
  machine_type = "${var.gcp_machine_type_client}"
  provider = "google.west"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  // for client binary
  scratch_disk {
    interface = "NVME"
  }

  metadata_startup_script = "${file("${path.module}/scripts/startup.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# provision azure resources
# ---------------------------------------------------------------------------------------------------------------------


resource "azurerm_resource_group" "sd_resource_group" {
  name = "sd-resource-group"
  location = "southcentralus"
}

resource "azurerm_virtual_network" "sd_virtual_network" {
  name = "sd-virtual-network"
  address_space = ["10.0.0.0/16"]
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
}

resource "azurerm_subnet" "sd_subnet" {
  name = "sd-subnet"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.sd_virtual_network.name}"
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "sd_public_ip" {
  count = "${var.region_node_count}"

  name = "sd-public-ip-${count.index}"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  allocation_method = "Dynamic"

}

resource "azurerm_network_security_group" "sd_security_group" {
  name = "sd-network-security-group"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"

  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "DB"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "26257"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }


  security_rule {
    name = "UI"
    priority = 1003
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "8080"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

}

resource "random_id" "sd_randomId" {
  keepers = {
    resource_group = "${azurerm_resource_group.sd_resource_group.name}"
  }

  byte_length = 8
}

resource "azurerm_network_interface" "sd_network_interface" {
  count = "${var.region_node_count}"

  name = "sd-network-interface-${count.index}"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.sd_security_group.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name = "sd-network-interface-config-${count.index}"
    subnet_id = "${azurerm_subnet.sd_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.sd_public_ip.*.id, count.index)}"
  }
}

resource "azurerm_virtual_machine" "sd_cockroach_node" {
  count = "${var.region_node_count}"

  name = "sd-azure-central-${count.index}"

  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.sd_network_interface.*.id, count.index)}"]
  vm_size = "${var.azure_machine_type}"

  storage_os_disk {
    name = "sd-os-disk-${count.index}"
    caching = "None"
    create_option = "FromImage"
    disk_size_gb = "${var.os_disk_size}"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "credativ"
    offer = "Debian"
    sku = "9"
    version = "latest"
  }

  os_profile {
    computer_name = "sd-azure-central-${count.index}"
    admin_username = "${var.azure_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.azure_user}/.ssh/authorized_keys"
      key_data = "${file(var.azure_public_key_path)}"
    }
  }

}

data "azurerm_public_ip" "sd_public_ip" {
  count = "${var.region_node_count}"

  name = "${element(azurerm_public_ip.sd_public_ip.*.name, count.index)}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"

  depends_on = ["azurerm_virtual_machine.sd_cockroach_node"]
}

# ---------------------------------------------------------------------------------------------------------------------
# locals
# ---------------------------------------------------------------------------------------------------------------------

locals {
  google_public_ips_east = "${concat(google_compute_instance.sd_east_cockroach_node.*.network_interface.0.access_config.0.nat_ip)}"
  google_public_ips_west = "${concat(google_compute_instance.sd_west_cockroach_node.*.network_interface.0.access_config.0.nat_ip)}"
  google_private_ips_east = "${concat(google_compute_instance.sd_east_cockroach_node.*.network_interface.0.network_ip)}"
  google_private_ips_west = "${concat(google_compute_instance.sd_west_cockroach_node.*.network_interface.0.network_ip)}"
  azure_private_ips = "${azurerm_network_interface.sd_network_interface.*.private_ip_address}"
}

# ---------------------------------------------------------------------------------------------------------------------
# start gcp clusters and clients
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "google_prep_east_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_east_cockroach_node"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_east, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/disks.sh"]
  }

}


resource "null_resource" "google_start_east_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "null_resource.google_prep_east_cluster"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_east, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update --fix-missing",
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=us-east1 --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_east, count.index)} --advertise-addr=${element(local.google_public_ips_east, count.index)} --join=${join(",", local.google_public_ips_east)}",
      "sleep ${var.provision_sleep}"
    ]
  }

}

resource "null_resource" "google_build_east_client" {

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_east_client"]

  connection {
    user = "${var.gcp_user}"
    host = "${google_compute_instance.sd_east_client.network_interface.0.access_config.0.nat_ip}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update --fix-missing",
      "sudo apt-get install -yq default-jdk git",
      "sleep ${var.provision_sleep}"
    ]
  }

}

resource "null_resource" "google_prep_west_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_west_cockroach_node"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_private_ips_west, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/disks.sh"]
  }

}

resource "null_resource" "google_start_west_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "null_resource.google_prep_west_cluster"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_west, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update --fix-missing",
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=us-west2 --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_west, count.index)} --advertise-addr=${element(local.google_public_ips_west, count.index)} --join=${join(",", local.google_public_ips_east)}",
      "sleep ${var.provision_sleep}"
    ]
  }

}

resource "null_resource" "google_build_west_client" {

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_west_client"]

  connection {
    user = "${var.gcp_user}"
    host = "${google_compute_instance.sd_west_client.network_interface.0.access_config.0.nat_ip}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update --fix-missing",
      "sudo apt-get install -yq default-jdk git",
      "sleep ${var.provision_sleep}"
    ]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# start azure cluster and client
# ---------------------------------------------------------------------------------------------------------------------

# Azure
resource "null_resource" "azure_install_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "data.azurerm_public_ip.sd_public_ip",
    "azurerm_virtual_machine.sd_cockroach_node",
    "null_resource.google_start_west_cluster"]

  connection {
    user = "${var.azure_user}"
    host = "${element(data.azurerm_public_ip.sd_public_ip.*.ip_address, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update --fix-missing",
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=azure,region=southcentralus --locality-advertise-addr=cloud=azure@${element(local.azure_private_ips, count.index)} --advertise-addr=${element(data.azurerm_public_ip.sd_public_ip.*.ip_address, count.index)} --join=${join(",", local.google_public_ips_west)}",
      "sleep ${var.provision_sleep}"
    ]
  }

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
    inline = ["cockroach init --insecure"]
  }

}