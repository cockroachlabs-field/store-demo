output "google_cockroach_public_ips_east" {
  description = "Public IP's of Cockroach Nodes in GCP - East"
  value = "${join(",", local.google_public_ips_east)}"
}

output "google_cockroach_public_ips_west" {
  description = "Public IP's of Cockroach Nodes in GCP - West"
  value = "${join(",", local.google_public_ips_west)}"
}

output "azure_cockroach_public_ips" {
  description = "Public IP's of Cockroach Nodes in Azure"
  value = "${join(",", data.azurerm_public_ip.sd_public_ip.*.ip_address)}"
}