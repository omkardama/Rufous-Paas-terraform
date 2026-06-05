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

output "pub_subnet_id" {
  value = [for network in module.vpc.subnets : network.id][2]
}

output "pvt_subnet_id" {
  value = [for network in module.vpc.subnets : network.id][0]
}

output "instance_pub_ip" {
  value = module.instance.instance_pub_ip
}

output "instance_pvt_ip" {
  value = module.instance.instance_pvt_ip
}
# output "repo_names" {
#   value = module.gcr.repo_names
# }
