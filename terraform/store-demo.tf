provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "cockroach-tv"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}


// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name = "crdb-vm-${random_id.instance_id.hex}"
  machine_type = "n1-standard-4"
  zone = "us-west1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "pd-ssd"
      size = "350"
    }
  }

  // Make sure flask is installed on all new instances for later steps
  metadata_startup_script = "sudo apt-get update"

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
