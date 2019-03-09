output "node_public_ips" {
  description = "Public IP's of Azure Nodes"
  value = "${data.azurerm_public_ip.public_ip_node_data.*.ip_address}"
}

output "node_private_ips" {
  description = "Private IP's of Azure Nodes"
  value = "${azurerm_network_interface.network_interface_node.*.private_ip_address}"
}

output "client_public_ips" {
  description = "Public IP of Azure Clients"
  value = "${data.azurerm_public_ip.public_ip_client_data.*.ip_address}"
}

output "client_private_ips" {
  description = "Private IP's of Azure Clients"
  value = "${azurerm_network_interface.network_interface_client.*.private_ip_address}"
}

output "lb_private_ip" {
  description = "Private IP of Azure Load Balancer"
  value = "${azurerm_lb.lb.private_ip_address}"
}