# todo: project and file should be variables
# todo: counts should be variables
# todo: can output be multiline?

# ---------------------------------------------------------------------------------------------------------------------
# setup gcp providers
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  credentials = "${file("gcp-account.json")}"
  project = "cockroach-tv"
}

provider "google" {
  alias = "east"
  region = "us-east1"
  zone = "us-east1-b"
  project = "cockroach-tv"

  credentials = "${file("gcp-account.json")}"
}

provider "google" {
  alias = "west"
  region = "us-west2"
  zone = "us-west2-b"
  project = "cockroach-tv"

  credentials = "${file("gcp-account.json")}"
}

provider "google" {
  alias = "central"
  region = "us-central1"
  zone = "us-central1-b"
  project = "cockroach-tv"

  credentials = "${file("gcp-account.json")}"
}

# ---------------------------------------------------------------------------------------------------------------------
# setup gcp network
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "google_vpc_network" {
  name = "crdb-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "google_sql" {
  name = "allow-crdb-sql"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["26257"]
  }

  target_tags = ["cockroach"]
}

resource "google_compute_firewall" "google_ui" {
  name = "allow-crdb-ui"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  target_tags = ["cockroach"]
}

resource "google_compute_firewall" "google_ssh" {
  name = "allow-ssh"
  network = "${google_compute_network.google_vpc_network.self_link}"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  target_tags = ["cockroach"]
}

# ---------------------------------------------------------------------------------------------------------------------
# provision gcp resources
# ---------------------------------------------------------------------------------------------------------------------

resource "google_compute_instance" "google_east_cockroach" {

  count = 3

  name = "crdb-gcp-east-${count.index}"
  machine_type = "n1-standard-4"
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
    network = "${google_compute_network.google_vpc_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "google_east_client" {

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
    network = "${google_compute_network.google_vpc_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "google_west_cockroach" {

  count = 3

  name = "crdb-gcp-west-${count.index}"
  machine_type = "n1-standard-4"
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
    network = "${google_compute_network.google_vpc_network.self_link}"

    access_config {}
  }

}

resource "google_compute_instance" "google_west_client" {

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
    network = "${google_compute_network.google_vpc_network.self_link}"

    access_config {}
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# locals
# ---------------------------------------------------------------------------------------------------------------------

locals {
  google_public_ips = "${concat(google_compute_instance.google_east_cockroach.*.network_interface.0.access_config.0.nat_ip, google_compute_instance.google_west_cockroach.*.network_interface.0.access_config.0.nat_ip)}"
  google_private_ips = "${concat(google_compute_instance.google_east_cockroach.*.network_interface.0.network_ip, google_compute_instance.google_west_cockroach.*.network_interface.0.network_ip)}"
  google_dns_names = "${concat(google_compute_instance.google_east_cockroach.*.name, google_compute_instance.google_west_cockroach.*.name)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# start gcp cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "google_start_cluster" {

  # todo turn into variable
  count = 6

  depends_on = ["google_compute_firewall.google_ssh"]

  connection {
    user = "timveil"
    host = "${element(local.google_public_ips, count.index)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach start --insecure --cache=.25 --max-sql-memory=.25 --background --advertise-addr=${element(local.google_public_ips, count.index)} --join=${join(",", local.google_public_ips)}",
      "sleep 20"
    ]
  }

}


# ---------------------------------------------------------------------------------------------------------------------
# init gcp cluster
# ---------------------------------------------------------------------------------------------------------------------

# todo this becomes generic; depends on azure and google but will call into google to start

resource "null_resource" "google_init_cluster" {

  depends_on = ["null_resource.google_start_cluster"]

  connection {
    user = "timveil"
    host = "${element(local.google_public_ips, 0)}"
    private_key = "${file("~/.ssh/google_compute_engine")}"
  }

  provisioner "remote-exec" {
    inline = ["cockroach init --insecure"]
  }

}