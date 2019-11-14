output "node_public_ips" {
  value = "${map("a", list(module.a.node_public_ips), "b", list(module.b.node_public_ips), "c", list(module.c.node_public_ips), "d", list(module.d.node_public_ips))}"
}

output "client_public_ips" {
  value = "${map("a", list(module.a.client_public_ips), "b", list(module.b.client_public_ips), "c", list(module.c.client_public_ips), "d", list(module.d.client_public_ips))}"
}

output "loadbalancer_private_ips" {
  value = "${map("a", list(module.a.lb_private_ip), "b", list(module.b.lb_private_ip), "c", list(module.c.lb_private_ip), "d", list(module.d.lb_private_ip))}"
}