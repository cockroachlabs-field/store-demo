# todo: project and file should be variables
# todo: counts should be variables
# todo: can output be multiline?

# ---------------------------------------------------------------------------------------------------------------------
# setup gcp providers
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "${var.gcp_project_name}"
}

provider "google" {
  alias = "east"
  region = "us-east1"
  zone = "us-east1-b"
  project = "${var.gcp_project_name}"

  credentials = "${file("gcp-account.json")}"
}

provider "google" {
  alias = "west"
  region = "us-west2"
  zone = "us-west2-b"
  project = "${var.gcp_project_name}"

  credentials = "${file("gcp-account.json")}"
}

provider "google" {
  alias = "central"
  region = "us-central1"
  zone = "us-central1-b"
  project = "${var.gcp_project_name}"

  credentials = "${file("gcp-account.json")}"
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

  count = 3

  name = "crdb-gcp-east-${count.index}"
  machine_type = "n1-standard-16"
  min_cpu_platform = "Intel Skylake"
  provider = "google.east"

  tags = ["cockroach"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      size = "350"
    }
  }

  scratch_disk {}

  metadata_startup_script = "${file("${path.module}/scripts/install-crdb.sh")}"

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
      image = "debian-cloud/debian-9"
      size = "350"
    }
  }

  scratch_disk {}

  metadata_startup_script = "${file("${path.module}/scripts/install-client.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "sd_west_cockroach_node" {

  count = 3

  name = "crdb-gcp-west-${count.index}"
  machine_type = "n1-standard-16"
  min_cpu_platform = "Intel Skylake"
  provider = "google.west"

  tags = ["cockroach"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      size = "350"
    }
  }

  scratch_disk {}

  metadata_startup_script = "${file("${path.module}/scripts/install-crdb.sh")}"

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "sd_west_client" {

  name = "crdb-gcp-west-client"
  machine_type = "n1-standard-4"
  provider = "google.west"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      size = "350"
    }
  }

  scratch_disk {}

  metadata_startup_script = "${file("${path.module}/scripts/install-client.sh")}"

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
  count = 3

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
  count = 3

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
  count = 3

  name = "sd-azure-central-${count.index}"

  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.sd_network_interface.*.id, count.index)}"]
  vm_size = "Standard_DS15_v2"

  storage_os_disk {
    name = "sd-os-disk-${count.index}"
    caching = "None"
    create_option = "FromImage"
    disk_size_gb = 350
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
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

}

data "azurerm_public_ip" "sd_public_ip" {
  count = 3

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
# start gcp cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "google_start_east_cluster" {

  count = 3

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_east_cockroach_node"]

  connection {
    user = "timveil"
    host = "${element(local.google_public_ips_east, count.index)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --locality=country=us,cloud=gcp,region=us-east1 --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_east, count.index)} --advertise-addr=${element(local.google_public_ips_east, count.index)} --join=${join(",", local.google_public_ips_east)}",
      "sleep 20"
    ]
  }

}

resource "null_resource" "google_start_west_cluster" {

  count = 3

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_west_cockroach_node",
    "null_resource.google_start_east_cluster"]

  connection {
    user = "timveil"
    host = "${element(local.google_public_ips_west, count.index)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --locality=country=us,cloud=gcp,region=us-west2 --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_west, count.index)} --advertise-addr=${element(local.google_public_ips_west, count.index)} --join=${join(",", local.google_public_ips_east)}",
      "sleep 20"
    ]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# install azure cluster
# ---------------------------------------------------------------------------------------------------------------------

# Azure
resource "null_resource" "azure_install_cluster" {

  count = 3

  depends_on = [
    "data.azurerm_public_ip.sd_public_ip",
    "azurerm_virtual_machine.sd_cockroach_node",
    "null_resource.google_start_west_cluster"]

  connection {
    user = "azureuser"
    host = "${element(data.azurerm_public_ip.sd_public_ip.*.ip_address, count.index)}"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-v2.1.5.linux-amd64.tgz | tar  xvz",
      "sudo cp -i cockroach-v2.1.5.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --locality=country=us,cloud=azure,region=southcentralus --locality-advertise-addr=cloud=azure@${element(local.azure_private_ips, count.index)} --advertise-addr=${element(data.azurerm_public_ip.sd_public_ip.*.ip_address, count.index)} --join=${join(",", local.google_public_ips_west)}",
      "sleep 20"
    ]
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# init global cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "global_init_cluster" {

  depends_on = ["null_resource.azure_install_cluster"]

  connection {
    user = "timveil"
    host = "${element(local.google_public_ips_east, 0)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = ["cockroach init --insecure"]
  }

}