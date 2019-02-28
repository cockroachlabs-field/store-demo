output "google_cockroach_public_ips" {
  description = "Public IP's of Cockroach Nodes in GCP"
  value = "${join(",", local.google_public_ips)}"
}
output "azure_cockroach_public_ips" {
  description = "Public IP's of Cockroach Nodes in Azure"
  value = "${join(",", local.azure_public_ips)}"
}

output "google_cockroach_private_ips" {
  description = "Private IP's of Cockroach Nodes in GCP"
  value = "${join(",", local.google_private_ips)}"
}

output "google_cockroach_instances" {
  description = "Names of Cockroach Nodes in GCP"
  value = "${join(",", local.google_dns_names)}"
}

output "google_admin_urls" {
  description = "Admin URL's for Cockroach Nodes"
  value = "${join(",", formatlist("http://%s:8080/", local.google_public_ips))}"
}