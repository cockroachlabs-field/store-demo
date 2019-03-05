output "google_cockroach_public_ips_east" {
  description = "Public IP's of Cockroach Nodes in GCP - East"
  value = "${join(",", local.google_public_ips_east)}"
}

output "google_client_public_ip_east" {
  description = "Public IP of Client in GCP - East"
  value = "${google_compute_instance.sd_east_client.network_interface.0.access_config.0.nat_ip}"
}

output "google_lb_private_ip_east" {
  description = "Private IP of LB in GCP - East"
  value = "${local.google_lb_ip_east}"
}

output "google_cockroach_public_ips_west" {
  description = "Public IP's of Cockroach Nodes in GCP - West"
  value = "${join(",", local.google_public_ips_west)}"
}

output "google_client_public_ip_west" {
  description = "Public IP of Client in GCP - West"
  value = "${google_compute_instance.sd_west_client.network_interface.0.access_config.0.nat_ip}"
}

output "google_lb_private_ip_west" {
  description = "Private IP of LB in GCP - West"
  value = "${local.google_lb_ip_west}"
}

output "azure_cockroach_public_ips" {
  description = "Public IP's of Cockroach Nodes in Azure"
  value = "${join(",", data.azurerm_public_ip.sd_public_ip_node.*.ip_address)}"
}

output "azure_client_public_ip" {
  description = "Public IP of Client in Azure"
  value = "${data.azurerm_public_ip.sd_public_ip_client.ip_address}"
}

output "azure_lb_private_ip" {
  description = "Private IP of LB in Azure"
  value = "${local.azure_lb_ip}"
}