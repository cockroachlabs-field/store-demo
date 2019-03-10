provider "azurerm" {
}

resource "random_pet" "random" {
}

locals {
  prefix = "${var.cluster_name}-${random_pet.random.id}"
  lb_frontend = "${local.prefix}-lb-frontend"
}

# ---------------------------------------------------------------------------------------------------------------------
# resources
# ---------------------------------------------------------------------------------------------------------------------


resource "azurerm_resource_group" "resource_group" {
  name = "${local.prefix}-resource-group"
  location = "${var.location}"
}

resource "azurerm_availability_set" "availability_set" {
  name = "${local.prefix}-availability-set"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  managed = "true"
}

resource "azurerm_virtual_network" "virtual_network" {
  name = "${local.prefix}-virtual-network"
  address_space = ["10.0.0.0/16"]
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
}

resource "azurerm_subnet" "subnet" {
  name = "${local.prefix}-subnet"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.virtual_network.name}"
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "security_group" {
  name = "${local.prefix}-network-security-group"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  security_rule {
    name = "ssh"
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
    name = "jdbc"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "${var.jdbc_port}"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "ui"
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

resource "azurerm_lb" "lb" {
  name = "${local.prefix}-lb"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  location = "${azurerm_resource_group.resource_group.location}"

  frontend_ip_configuration {
    name = "${local.lb_frontend}"
    subnet_id = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  name = "${local.prefix}-lb-backend-pool"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id = "${azurerm_lb.lb.id}"
}

resource "azurerm_lb_probe" "lb_probe" {
  name = "${local.prefix}-lb-probe"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id = "${azurerm_lb.lb.id}"
  protocol = "Http"
  port = 8080
  request_path = "/health?ready=1"
  interval_in_seconds = 5
  number_of_probes = 2
}


resource "azurerm_lb_rule" "lb_rule" {
  name = "${local.prefix}-lb-rule"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  loadbalancer_id = "${azurerm_lb.lb.id}"
  protocol = "tcp"
  frontend_port = "${var.jdbc_port}"
  backend_port = "${var.jdbc_port}"
  frontend_ip_configuration_name = "${local.lb_frontend}"
  enable_floating_ip = false
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_backend_pool.id}"
  idle_timeout_in_minutes = 5
  probe_id = "${azurerm_lb_probe.lb_probe.id}"
  depends_on = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_public_ip" "public_ip_node" {
  count = "${var.node_count}"

  name = "${local.prefix}-public-ip-node-${count.index}"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "network_interface_node" {
  count = "${var.node_count}"

  name = "${local.prefix}-network-interface-node-${count.index}"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.security_group.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name = "${local.prefix}-network-interface-node-config-${count.index}"
    subnet_id = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.public_ip_node.*.id, count.index)}"

  }
}

resource "azurerm_network_interface_backend_address_pool_association" "network_interface_backend_pool" {
  count = "${var.node_count}"

  ip_configuration_name = "${local.prefix}-network-interface-node-config-${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.lb_backend_pool.id}"
  network_interface_id = "${element(azurerm_network_interface.network_interface_node.*.id, count.index)}"
}

resource "azurerm_virtual_machine" "nodes" {
  count = "${var.node_count}"

  name = "${local.prefix}-node-${count.index}"

  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.network_interface_node.*.id, count.index)}"]
  vm_size = "${var.node_machine_type}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  availability_set_id = "${azurerm_availability_set.availability_set.id}"

  storage_os_disk {
    name = "${local.prefix}-os-disk-node-${count.index}"
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
    computer_name = "${local.prefix}-node-${count.index}"
    admin_username = "${var.user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }

}

data "azurerm_public_ip" "public_ip_node_data" {
  count = "${var.node_count}"

  name = "${element(azurerm_public_ip.public_ip_node.*.name, count.index)}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  depends_on = ["azurerm_virtual_machine.nodes"]
}


resource "azurerm_public_ip" "public_ip_client" {
  count = "${var.client_count}"

  name = "${local.prefix}-public-ip-client-${count.index}"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "network_interface_client" {
  count = "${var.client_count}"

  name = "${local.prefix}-network-interface-client-${count.index}"
  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  network_security_group_id = "${azurerm_network_security_group.security_group.id}"
  enable_accelerated_networking = true

  ip_configuration {
    name = "${local.prefix}-network-interface-client-config-${count.index}"
    subnet_id = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.public_ip_client.*.id, count.index)}"

  }
}


resource "azurerm_virtual_machine" "clients" {
  count = "${var.client_count}"

  name = "${local.prefix}-client-${count.index}"

  location = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.network_interface_client.*.id, count.index)}"]
  vm_size = "${var.client_machine_type}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name = "${local.prefix}-os-disk-client-${count.index}"
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
    computer_name = "${local.prefix}-node-${count.index}"
    admin_username = "${var.user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }

}

data "azurerm_public_ip" "public_ip_client_data" {
  count = "${var.client_count}"

  name = "${element(azurerm_public_ip.public_ip_client.*.name, count.index)}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  depends_on = ["azurerm_virtual_machine.clients"]
}

# ---------------------------------------------------------------------------------------------------------------------
# null resources
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "prep_nodes" {

  count = "${var.node_count}"

  depends_on = [
    "data.azurerm_public_ip.public_ip_node_data",
    "azurerm_virtual_machine.nodes"]

  connection {
    user = "${var.user}"
    host = "${element(data.azurerm_public_ip.public_ip_node_data.*.ip_address, count.index)}"
    private_key = "${file(var.private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    scripts = ["${path.root}/scripts/startup.sh",
      "${path.root}/scripts/disks.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.sleep}"]
  }

}


resource "null_resource" "prep_clients" {

  count = "${var.client_count}"

  depends_on = [
    "data.azurerm_public_ip.public_ip_client_data",
    "azurerm_virtual_machine.clients"]

  connection {
    user = "${var.user}"
    host = "${element(data.azurerm_public_ip.public_ip_client_data.*.ip_address, count.index)}"
    private_key = "${file(var.private_key_path)}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    scripts = ["${path.root}/scripts/startup.sh"]
  }

  provisioner "remote-exec" {
    scripts = ["${path.root}/scripts/client-build.sh"]
  }

  provisioner "remote-exec" {
    inline = ["sleep ${var.sleep}"]
  }


}
