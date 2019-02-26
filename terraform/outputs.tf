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