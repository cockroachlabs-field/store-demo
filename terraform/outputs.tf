# ---------------------------------------------------------------------------------------------------------------------
# gcp east
# ---------------------------------------------------------------------------------------------------------------------

output "gcp_east_public_node_ips" {
  value = "${join(",", module.gcp_east.node_public_ips)}"
}

output "gcp_east_private_node_ips" {
  value = "${join(",", module.gcp_east.node_private_ips)}"
}

output "gcp_east_public_client_ips" {
  value = "${join(",", module.gcp_east.client_public_ips)}"
}

output "gcp_east_private_client_ips" {
  value = "${join(",", module.gcp_east.client_private_ips)}"
}

output "gcp_east_private_lb_ip" {
  value = "${module.gcp_east.lb_private_ip}"
}

# ---------------------------------------------------------------------------------------------------------------------
# gcp west
# ---------------------------------------------------------------------------------------------------------------------

output "gcp_west_public_node_ips" {
  value = "${join(",", module.gcp_west.node_public_ips)}"
}

output "gcp_west_private_node_ips" {
  value = "${join(",", module.gcp_west.node_private_ips)}"
}

output "gcp_west_public_client_ips" {
  value = "${join(",", module.gcp_west.client_public_ips)}"
}

output "gcp_west_private_client_ips" {
  value = "${join(",", module.gcp_west.client_private_ips)}"
}

output "gcp_west_private_lb_ip" {
  value = "${module.gcp_west.lb_private_ip}"
}

# ---------------------------------------------------------------------------------------------------------------------
# azure east
# ---------------------------------------------------------------------------------------------------------------------

output "azure_east_public_node_ips" {
  value = "${join(",", module.azure_east.node_public_ips)}"
}

output "azure_east_private_node_ips" {
  value = "${join(",", module.azure_east.node_private_ips)}"
}

output "azure_east_public_client_ips" {
  value = "${join(",", module.azure_east.client_public_ips)}"
}

output "azure_east_private_client_ips" {
  value = "${join(",", module.azure_east.client_private_ips)}"
}

output "azure_east_private_lb_ip" {
  value = "${module.azure_east.lb_private_ip}"
}
