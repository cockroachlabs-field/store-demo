provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "cockroach-tv"
}


resource "google_compute_instance" "google_cockroach" {

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
    network = "${google_compute_network.google_vpc_network.self_link}"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

resource "google_compute_network" "google_vpc_network" {
  name = "crdb-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "google_sql" {
  name = "allow-crdb-sql"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "26257"]
  }

  target_tags = [
    "cockroach"]
}

resource "google_compute_firewall" "google_ui" {
  name = "allow-crdb-ui"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "8080"]
  }

  target_tags = [
    "cockroach"]
}

resource "google_compute_firewall" "google_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = [
      "22"]
  }

  target_tags = [
    "cockroach"]
}

output "google_cockroach_public_ips" {
  description = "Public IP's of Cockroach Nodes"
  value = "${join(",", google_compute_instance.google_cockroach.*.network_interface.0.access_config.0.nat_ip)}"
}

output "google_cockroach_private_ips" {
  description = "Private IP's of Cockroach Nodes"
  value = "${join(",", google_compute_instance.google_cockroach.*.network_interface.0.network_ip)}"
}

output "google_cockroach_instances" {
  description = "Names of Cockroach Nodes"
  value = "${join(",", google_compute_instance.google_cockroach.*.name)}"
}

output "google_admin_urls" {
  description = "Admin URL's for Cockroach Nodes"
  value = "${join(",", formatlist("http://%s:8080/", google_compute_instance.google_cockroach.*.network_interface.0.access_config.0.nat_ip))}"
}

resource "null_resource" "google_start_cluster" {

  count = 3

  connection {
    user = "timveil"
    host = "${element(google_compute_instance.google_cockroach.*.network_interface.0.access_config.0.nat_ip, count.index)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --advertise-addr=${element(google_compute_instance.google_cockroach.*.network_interface.0.access_config.0.nat_ip, count.index)} --join=${join(",", google_compute_instance.google_cockroach.*.network_interface.0.access_config.0.nat_ip)}",
      "sleep 20"
    ]
  }

  depends_on = [
    "google_compute_firewall.google_ssh"]

}

resource "null_resource" "google_init_cluster" {

  connection {
    user = "timveil"
    host = "${google_compute_instance.google_cockroach.0.network_interface.0.access_config.0.nat_ip}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --insecure"
    ]
  }

  depends_on = [
    "null_resource.google_start_cluster"]

}