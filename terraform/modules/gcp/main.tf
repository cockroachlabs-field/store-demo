provider "google" {
  region = "${var.region}"
  zone = "${var.zone}"
  project = "${var.project}"

  credentials = "${file(var.credentials_file)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# resources
# ---------------------------------------------------------------------------------------------------------------------

resource "random_pet" "random" {
}

resource "google_compute_network" "compute_network" {
  name = "${var.prefix}-network-${random_pet.random.id}"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "firewall_jdbc" {
  name = "${var.prefix}-allow-jdbc"
  network = "${google_compute_network.compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["${var.jdbc_port}"]
  }
}

resource "google_compute_firewall" "firewall_ui" {
  name = "${var.prefix}-allow-ui"
  network = "${google_compute_network.compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["8080"]
  }
}

resource "google_compute_firewall" "firewall_ssh" {
  name = "${var.prefix}-allow-ssh"
  network = "${google_compute_network.compute_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_health_check" "health_check" {
  name = "${var.prefix}-health-check-${random_pet.random.id}"

  http_health_check {
    port = "8080"
    request_path = "/health?ready=1"
  }
}

resource "google_compute_instance" "node_instances" {

  count = "${var.node_count}"

  name = "${var.prefix}-node-${count.index}"
  machine_type = "${var.node_machine_type}"
  min_cpu_platform = "Intel Skylake"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "${google_compute_network.compute_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance_group" "node_instance_group" {
  name = "${var.prefix}-node-group"

  instances = ["${google_compute_instance.node_instances.*.self_link}"]

  zone = "${var.zone}"
}

resource "google_compute_region_backend_service" "backend_service" {
  name = "${var.prefix}-backend-service"
  health_checks = ["${google_compute_health_check.health_check.self_link}"]
  region = "${var.region}"

  backend {
    group = "${google_compute_instance_group.node_instance_group.self_link}"
  }

}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  name = "${var.prefix}-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  ip_protocol = "TCP"
  region = "${var.region}"
  ports = ["${var.jdbc_port}"]
  network = "${google_compute_network.compute_network.self_link}"
  backend_service = "${google_compute_region_backend_service.backend_service.self_link}"
}


resource "google_compute_instance" "client_instances" {

  count = "${var.client_count}"

  name = "${var.prefix}-client-${count.index}"
  machine_type = "${var.client_machine_type}"
  min_cpu_platform = "Intel Skylake"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size = "${var.os_disk_size}"
      type = "pd-ssd"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "${google_compute_network.compute_network.self_link}"

    access_config {}
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# null resources
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "prep_nodes" {

  count = "${var.node_count}"

  depends_on = [
    "google_compute_firewall.firewall_ssh",
    "google_compute_instance.node_instances"]

  connection {
    user = "${var.user}"
    host = "${element(google_compute_instance.node_instances.*.network_interface.0.access_config.0.nat_ip, count.index)}"
    private_key = "${file(var.private_key_path)}"
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
    "google_compute_firewall.firewall_ssh",
    "google_compute_instance.client_instances"]

  connection {
    user = "${var.user}"
    host = "${element(google_compute_instance.client_instances.*.network_interface.0.access_config.0.nat_ip, count.index)}"
    private_key = "${file(var.private_key_path)}"
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
