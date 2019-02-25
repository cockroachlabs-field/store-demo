provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "cockroach-tv"
}


resource "google_compute_instance" "cockroach" {

  count = 3

  name = "crdb-gcp-${count.index}"
  machine_type = "n1-standard-4"
  zone = "us-east4-a"

  tags = [
    "cockroach"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-ssd"
      size = "350"
    }
  }

  metadata_startup_script = "${file("${path.module}/scripts/install.sh")}"

  network_interface {
    network = "${google_compute_network.vpc_network.self_link}"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }


  provisioner "remote-exec" {
    inline = [
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --join=${self.network_interface.0.network_ip}"
    ]

    connection {
      timeout = "5s"
      user = "timveil"
      private_key = "${file("~/.ssh/google_compute_engine")}"
    }

  }

  depends_on = [
    "google_compute_firewall.ssh"]
}

resource "google_compute_network" "vpc_network" {
  name = "crdb-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "sql" {
  name = "allow-crdb-sql"
  network = "${google_compute_network.vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "26257"]
  }

  target_tags = [
    "cockroach"]
}

resource "google_compute_firewall" "ui" {
  name = "allow-crdb-ui"
  network = "${google_compute_network.vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "8080"]
  }

  target_tags = [
    "cockroach"]
}

resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "22"]
  }

  target_tags = [
    "cockroach"]
}

output "google_cockroach_ips" {
  value = "${join(",", google_compute_instance.cockroach.*.network_interface.0.access_config.0.nat_ip)}"
}

output "google_cockroach_instances" {
  value = "${join(",", google_compute_instance.cockroach.*.name)}"
}

output "google_admin_urls" {
  value = "${join(",", formatlist("http://%s:8080/", google_compute_instance.cockroach.*.network_interface.0.access_config.0.nat_ip))}"
}