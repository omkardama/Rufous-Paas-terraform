output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway"
  value       = google_compute_router_nat.nat.name
}

output "nat_ip_addresses" {
  description = "Static external IPs used by Cloud NAT — whitelist these in MongoDB Atlas"
  value       = google_compute_address.nat[*].address
}

output "nat_ip_self_links" {
  description = "Self-links of the reserved NAT external IPs"
  value       = google_compute_address.nat[*].self_link
}
