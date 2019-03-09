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