output "node_public_ips" {
  value = "${map("a", module.a.node_public_ips, "b", module.b.node_public_ips, "c", module.c.node_public_ips, "d", module.d.node_public_ips, "e", module.e.node_public_ips, "f", module.f.node_public_ips)}"
}

output "client_public_ips" {
  value = "${map("a", module.a.client_public_ips, "b", module.b.client_public_ips, "c", module.c.client_public_ips, "d", module.d.client_public_ips, "e", module.e.client_public_ips, "f", module.f.client_public_ips)}"
}

output "loadbalancer_private_ips" {
  value = "${map("a", module.a.lb_private_ip, "b", module.b.lb_private_ip, "c", module.c.lb_private_ip, "d", module.d.lb_private_ip, "e", module.e.lb_private_ip, "f", module.f.lb_private_ip)}"
}