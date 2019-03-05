# ---------------------------------------------------------------------------------------------------------------------
# setup gcp providers
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

provider "google" {
  alias = "east"
  region = "${var.gcp_east_region}"
  zone = "${var.gcp_east_zone}"
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

provider "google" {
  alias = "west"
  region = "${var.gcp_west_region}"
  zone = "${var.gcp_west_zone}"
  project = "${var.gcp_project_name}"

  credentials = "${file(var.gcp_credentials_file)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# setup azure provider
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
}

# ---------------------------------------------------------------------------------------------------------------------
# provision common gcp resources
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

resource "google_compute_firewall" "sd_client_ui" {
  name = "allow-client-ui"
  network = "${google_compute_network.sd_compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["8082"]
  }
}

resource "google_compute_health_check" "sd_health_check" {
  name = "sd-health-check"

  http_health_check {
    port = "8080"
    request_path = "/health?ready=1"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# provision east gcp resources
# ---------------------------------------------------------------------------------------------------------------------

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

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance_group" "sd_east_node_group" {
  name = "sd-east-node-group"

  instances = ["${google_compute_instance.sd_east_cockroach_node.*.self_link}"]

  zone = "${var.gcp_east_zone}"
}

resource "google_compute_region_backend_service" "sd_east_lb" {
  name = "sd-east-lb"
  health_checks = ["${google_compute_health_check.sd_health_check.self_link}"]
  region = "${var.gcp_east_region}"

  backend {
    group = "${google_compute_instance_group.sd_east_node_group.self_link}"
  }

}

resource "google_compute_forwarding_rule" "sd_east_lb_forwarding_rule" {
  name = "sd-east-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  ip_protocol = "TCP"
  region = "${var.gcp_east_region}"
  ports = ["26257"]
  network = "${google_compute_network.sd_compute_network.self_link}"
  backend_service = "${google_compute_region_backend_service.sd_east_lb.self_link}"
}


resource "google_compute_instance" "sd_east_client" {

  name = "crdb-gcp-east-client"
  machine_type = "${var.gcp_machine_type_client}"
  min_cpu_platform = "Intel Skylake"
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

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# provision west gcp resources
# ---------------------------------------------------------------------------------------------------------------------

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

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance_group" "sd_west_node_group" {
  name = "sd-west-node-group"

  instances = ["${google_compute_instance.sd_west_cockroach_node.*.self_link}"]

  zone = "${var.gcp_west_zone}"
}

resource "google_compute_region_backend_service" "sd_west_lb" {
  name = "sd-west-lb"
  health_checks = ["${google_compute_health_check.sd_health_check.self_link}"]
  region = "${var.gcp_west_region}"

  backend {
    group = "${google_compute_instance_group.sd_west_node_group.self_link}"
  }

}


resource "google_compute_forwarding_rule" "sd_west_lb_forwarding_rule" {
  name = "sd-west-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  ip_protocol = "TCP"
  region = "${var.gcp_west_region}"
  ports = ["26257"]
  network = "${google_compute_network.sd_compute_network.self_link}"
  backend_service = "${google_compute_region_backend_service.sd_west_lb.self_link}"
}

resource "google_compute_instance" "sd_west_client" {

  name = "crdb-gcp-west-client"
  machine_type = "${var.gcp_machine_type_client}"
  min_cpu_platform = "Intel Skylake"
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

  network_interface {
    network = "${google_compute_network.sd_compute_network.self_link}"

    access_config {}
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# provision azure common resources
# ---------------------------------------------------------------------------------------------------------------------


resource "azurerm_resource_group" "sd_resource_group" {
  name = "sd-resource-group"
  location = "eastus2"
}

resource "azurerm_availability_set" "sd_availability_set" {
  name = "sd-availability-set"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  managed = "true"
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

  security_rule {
    name = "client"
    priority = 1004
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "8082"
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

resource "azurerm_lb" "sd_lb" {
  name = "sd-lb"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  location = "${azurerm_resource_group.sd_resource_group.location}"

  frontend_ip_configuration {
    name = "sd-lb-frontend"
    subnet_id = "${azurerm_subnet.sd_subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "sd_lb_backend_pool" {
  name = "sd-lb-backend-pool"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  loadbalancer_id = "${azurerm_lb.sd_lb.id}"
}

resource "azurerm_lb_probe" "sd_lb_probe" {
  name = "sd-lb-probe"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  loadbalancer_id = "${azurerm_lb.sd_lb.id}"
  protocol = "Http"
  port = 8080
  request_path = "/health?ready=1"
  interval_in_seconds = 5
  number_of_probes = 2
}


resource "azurerm_lb_rule" "sd_lb_rule" {
  name = "sd-lb-rule"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  loadbalancer_id = "${azurerm_lb.sd_lb.id}"
  protocol = "tcp"
  frontend_port = 26257
  backend_port = 26257
  frontend_ip_configuration_name = "sd-lb-frontend"
  enable_floating_ip = false
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.sd_lb_backend_pool.id}"
  idle_timeout_in_minutes = 5
  probe_id = "${azurerm_lb_probe.sd_lb_probe.id}"
  depends_on = ["azurerm_lb_probe.sd_lb_probe"]
}

# ---------------------------------------------------------------------------------------------------------------------
# provision azure node resources
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_public_ip" "sd_public_ip_node" {
  count = "${var.region_node_count}"

  name = "sd-public-ip-node-${count.index}"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_interface" "sd_network_interface_node" {
  count = "${var.region_node_count}"

  name = "sd-network-interface-node-${count.index}"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.sd_security_group.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name = "sd-network-interface-node-config-${count.index}"
    subnet_id = "${azurerm_subnet.sd_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.sd_public_ip_node.*.id, count.index)}"

  }
}

resource "azurerm_network_interface_backend_address_pool_association" "sd_network_interface_backend_pool" {
  count = 3

  ip_configuration_name = "sd-network-interface-node-config-${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.sd_lb_backend_pool.id}"
  network_interface_id = "${element(azurerm_network_interface.sd_network_interface_node.*.id, count.index)}"
}

resource "azurerm_virtual_machine" "sd_cockroach_node" {
  count = "${var.region_node_count}"

  name = "sd-azure-central-node-${count.index}"

  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.sd_network_interface_node.*.id, count.index)}"]
  vm_size = "${var.azure_machine_type}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  availability_set_id = "${azurerm_availability_set.sd_availability_set.id}"

  storage_os_disk {
    name = "sd-os-disk-node-${count.index}"
    create_option = "FromImage"
    caching = "None"
    disk_size_gb = "${var.os_disk_size}"
    os_type = "Linux"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  storage_data_disk {
    name = "sd-data-disk-node-${count.index}"
    create_option = "Empty"
    lun = 0
    disk_size_gb = "${var.azure_storage_disk_size}"
  }

  os_profile {
    computer_name = "sd-azure-central-node-${count.index}"
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

data "azurerm_public_ip" "sd_public_ip_node" {
  count = "${var.region_node_count}"

  name = "${element(azurerm_public_ip.sd_public_ip_node.*.name, count.index)}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"

  depends_on = ["azurerm_virtual_machine.sd_cockroach_node"]
}

# ---------------------------------------------------------------------------------------------------------------------
# provision azure client resources
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_public_ip" "sd_public_ip_client" {
  name = "sd-public-ip-client"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_interface" "sd_network_interface_client" {
  name = "sd-network-interface-client"
  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.sd_security_group.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name = "sd-network-interface-client-config"
    subnet_id = "${azurerm_subnet.sd_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.sd_public_ip_client.id}"
  }
}


resource "azurerm_virtual_machine" "sd_cockroach_client" {
  name = "sd-azure-central-client"

  location = "${azurerm_resource_group.sd_resource_group.location}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"
  network_interface_ids = ["${azurerm_network_interface.sd_network_interface_client.id}"]
  vm_size = "${var.azure_machine_type_client}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "sd-os-disk-client"
    create_option = "FromImage"
    caching = "None"
    disk_size_gb = "${var.os_disk_size}"
    os_type = "Linux"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  os_profile {
    computer_name = "sd-azure-central-client"
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

data "azurerm_public_ip" "sd_public_ip_client" {
  name = "${azurerm_public_ip.sd_public_ip_client.name}"
  resource_group_name = "${azurerm_resource_group.sd_resource_group.name}"

  depends_on = ["azurerm_virtual_machine.sd_cockroach_client"]
}

# ---------------------------------------------------------------------------------------------------------------------
# locals
# ---------------------------------------------------------------------------------------------------------------------

locals {
  google_public_ips_east = "${concat(google_compute_instance.sd_east_cockroach_node.*.network_interface.0.access_config.0.nat_ip)}"
  google_public_ips_west = "${concat(google_compute_instance.sd_west_cockroach_node.*.network_interface.0.access_config.0.nat_ip)}"
  google_private_ips_east = "${concat(google_compute_instance.sd_east_cockroach_node.*.network_interface.0.network_ip)}"
  google_private_ips_west = "${concat(google_compute_instance.sd_west_cockroach_node.*.network_interface.0.network_ip)}"
  azure_private_ips = "${azurerm_network_interface.sd_network_interface_node.*.private_ip_address}"
  google_lb_ip_east = "${google_compute_forwarding_rule.sd_east_lb_forwarding_rule.ip_address}"
  google_lb_ip_west = "${google_compute_forwarding_rule.sd_west_lb_forwarding_rule.ip_address}"
  azure_lb_ip = "${azurerm_lb.sd_lb.private_ip_address}"
}

# ---------------------------------------------------------------------------------------------------------------------
# start gcp east clusters and clients
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
    scripts = ["scripts/startup.sh",
      "scripts/disks.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}


resource "null_resource" "google_start_east_cluster" {

  count = "${var.region_node_count}"

  depends_on = ["null_resource.google_prep_east_cluster"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_east, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=east --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_east, count.index)} --advertise-addr=${element(local.google_public_ips_east, count.index)} --join=${join(",", local.google_public_ips_east)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}

resource "null_resource" "google_prep_east_client" {

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_east_client"]

  connection {
    user = "${var.gcp_user}"
    host = "${google_compute_instance.sd_east_client.network_interface.0.access_config.0.nat_ip}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/startup.sh"]
  }

  provisioner "remote-exec" {
    scripts = ["scripts/client-build.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# start gcp west clusters and clients
# ---------------------------------------------------------------------------------------------------------------------


resource "null_resource" "google_prep_west_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_west_cockroach_node"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_west, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/startup.sh",
      "scripts/disks.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}

resource "null_resource" "google_start_west_cluster" {

  count = "${var.region_node_count}"

  depends_on = ["null_resource.google_prep_west_cluster"]

  connection {
    user = "${var.gcp_user}"
    host = "${element(local.google_public_ips_west, count.index)}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=gcp,region=west --locality-advertise-addr=cloud=gcp@${element(local.google_private_ips_west, count.index)} --advertise-addr=${element(local.google_public_ips_west, count.index)} --join=${join(",", local.google_public_ips_east)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}

resource "null_resource" "google_prep_west_client" {

  depends_on = [
    "google_compute_firewall.sd_ssh",
    "google_compute_instance.sd_west_client"]

  connection {
    user = "${var.gcp_user}"
    host = "${google_compute_instance.sd_west_client.network_interface.0.access_config.0.nat_ip}"
    private_key = "${file(var.gcp_private_key_path)}"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/startup.sh"]
  }

  provisioner "remote-exec" {
    scripts = ["scripts/client-build.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# start azure cluster and client
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "azure_prep_cluster" {

  count = "${var.region_node_count}"

  depends_on = [
    "data.azurerm_public_ip.sd_public_ip_node",
    "azurerm_virtual_machine.sd_cockroach_node",
    "null_resource.google_start_west_cluster"]

  connection {
    user = "${var.azure_user}"
    host = "${element(data.azurerm_public_ip.sd_public_ip_node.*.ip_address, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/startup.sh",
      "scripts/disks-azure.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}

resource "null_resource" "azure_install_cluster" {

  count = "${var.region_node_count}"

  depends_on = ["null_resource.azure_prep_cluster"]

  connection {
    user = "${var.azure_user}"
    host = "${element(data.azurerm_public_ip.sd_public_ip_node.*.ip_address, count.index)}"
    private_key = "${file(var.azure_private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO- https://binaries.cockroachdb.com/cockroach-${var.crdb_version}.linux-amd64.tgz | tar xvz",
      "sudo cp -i cockroach-${var.crdb_version}.linux-amd64/cockroach /usr/local/bin",
      "cockroach start --insecure --logtostderr=NONE --log-dir=/mnt/disks/cockroach --store=/mnt/disks/cockroach --cache=${var.crdb_cache} --max-sql-memory=${var.crdb_max_sql_memory} --background --locality=country=us,cloud=azure,region=central --locality-advertise-addr=cloud=azure@${element(local.azure_private_ips, count.index)} --advertise-addr=${element(data.azurerm_public_ip.sd_public_ip_node.*.ip_address, count.index)} --join=${join(",", local.google_public_ips_west)}"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
  }

}

resource "null_resource" "azure_prep_client" {

  count = "${var.region_node_count}"

  depends_on = [
    "data.azurerm_public_ip.sd_public_ip_client",
    "azurerm_virtual_machine.sd_cockroach_client"]

  connection {
    user = "${var.azure_user}"
    host = "${data.azurerm_public_ip.sd_public_ip_client.ip_address}"
    private_key = "${file(var.azure_private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    scripts = ["scripts/startup.sh"]
  }

  provisioner "remote-exec" {
    scripts = ["scripts/client-build.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.provision_sleep}"]
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