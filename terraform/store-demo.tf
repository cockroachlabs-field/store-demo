provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "cockroach-tv"
}


// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {

  count=3

  name = "crdb-gcp-${count.index}"
  machine_type = "n1-standard-4"
  zone = "us-west1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-ssd"
      size = "350"
    }
  }

  metadata_startup_script = "${file("${path.module}/scripts/bootstrap.sh")}"

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

resource "google_compute_firewall" "sql" {
  name = "allow-crdb-sql"
  network = "default"

  allow {
    protocol = "tcp"
    ports = [
      "26257"]
  }
}

resource "google_compute_firewall" "ui" {
  name = "allow-crdb-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports = [
      "8080"]
  }
}
