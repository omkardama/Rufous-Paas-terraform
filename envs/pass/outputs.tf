output "service_account_email" {
  value = module.serviceaccount.service_account_email
}

output "service_account_key_path" {
  value = module.serviceaccount.service_account_key_file_path
}

output "vpc_id" {
  value = module.vpc.network_id
}

output "subnet_ids" {
  value = [for network in module.vpc.subnets : network.id]
}

output "vpc_name" {
  value = module.vpc.network_name
}

output "nat_ip_addresses" {
  description = "Static external IPs used by Cloud NAT — add these to MongoDB Atlas IP access list"
  value       = module.cloud_nat.nat_ip_addresses
}

output "nat_router_name" {
  value = module.cloud_nat.router_name
}

output "nat_gateway_name" {
  value = module.cloud_nat.nat_name
}
