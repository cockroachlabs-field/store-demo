output "node_public_ips" {
  description = "Public IP's of Google Nodes"
  value = "${join(",", google_compute_instance.node_instances.*.network_interface.0.access_config.0.nat_ip)}"
}

output "client_public_ips" {
  description = "Public IP's of Google Clients"
  value = "${join(",", google_compute_instance.client_instances.network_interface.0.access_config.0.nat_ip)}"
}

output "lb_private_ip" {
  description = "Private IP of Google Load Balancer"
  value = "${google_compute_forwarding_rule.forwarding_rule.ip_address}"
}