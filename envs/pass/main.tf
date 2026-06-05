########################################################################
# SERVICE ACCOUNT
########################################################################
module "serviceaccount" {
  source     = "../../modules/serviceaccount"
  project_id = var.project_id
  env        = var.env
}


########################################################################
# GCS
########################################################################
module "gcs" {
  source                = "../../modules/gcs"
  env                   = var.env
  region                = var.region
  bucket_names          = var.bucket_names
  storage_class         = var.storage_class
  service_account_email = module.serviceaccount.service_account_email
  depends_on            = [module.serviceaccount]
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.3"

  project_id       = var.project_id
  network_name     = "${var.env}-vpc1"
  routing_mode     = var.vpc_routing_mode
  secondary_ranges = var.secondary_ranges

  delete_default_internet_gateway_routes = "true"

  subnets = concat(
    # create 2 public subnets
    [for k, v in var.public_subnet_cidr_block :
      {
        subnet_name           = "${var.env}-public-subnet-${k}"
        subnet_ip             = v
        subnet_region         = var.region
        subnet_private_access = "false"
        subnet_flow_logs      = "false"
    }],

    # create 2 private subnets
    [for k, v in var.private_subnet_cidr_block : {
      subnet_name           = "${var.env}-private-subnet-${k}"
      subnet_ip             = v
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
    }]
  )

  routes = [
    {
      name              = "${var.env}-default-igw1"
      description       = "Default route through IGW; untagged so it applies to all instances (incl. GKE nodes via Cloud NAT egress)"
      destination_range = "0.0.0.0/0"
      next_hop_internet = "true"
    }
  ]


}


########################################################################
# Cloud NAT — egress for private subnets to reach MongoDB Atlas
########################################################################
module "cloud_nat" {
  source = "../../modules/cloud-nat"

  env        = var.env
  project_id = var.project_id
  region     = var.region
  network    = module.vpc.network_name

  nat_subnetworks = [
    for k, _ in var.private_subnet_cidr_block :
    "${var.env}-private-subnet-${k}"
  ]

  nat_ip_count   = var.nat_ip_count
  enable_logging = true

  depends_on = [module.vpc]
}


module "mongodb" {
  source = "../../modules/mongodb"

  project_name = var.project_name
  environment  = var.environment
  org_id       = var.org_id

  cluster_name    = var.cluster_name
  cluster_tier    = var.cluster_tier
  gcp_region      = var.gcp_region
  mongodb_version = var.mongodb_version
  disk_size_gb    = var.disk_size_gb

  backup_enabled               = var.backup_enabled
  auto_scaling_disk_enabled    = var.auto_scaling_disk_enabled
  auto_scaling_compute_enabled = var.auto_scaling_compute_enabled

  gcp_project_id   = var.project_id
  gcp_network_name = module.vpc.network_name

  allowed_ip_addresses = concat(
    var.allowed_ip_addresses,
    [
      for ip in module.cloud_nat.nat_ip_addresses : {
        cidr_block = "${ip}/32"
        comment    = "Cloud NAT egress IP (${var.env})"
      }
    ],
  )
  database_users = var.database_users

  depends_on = [module.vpc, module.cloud_nat]
}
########################################################################
# Redis Variables
########################################################################
module "redis" {
  source         = "../../modules/redis"
  region         = var.region
  env            = var.env
  memory_size_gb = var.memory_size_gb
  redis_tier     = var.redis_tier
  vpc_id         = module.vpc.network_id
  depends_on     = [module.vpc]
}

########################################################################
# GCR
########################################################################
module "gcr" {
  source                = "../../modules/gcr"
  env                   = var.env
  repo_names            = var.repo_names
  user_email            = var.user_email
  service_account_email = module.serviceaccount.service_account_email
}


########################################################################
# Compute Engine
########################################################################
module "instance" {
  source                = "../../modules/instance"
  env                   = var.env
  zone                  = var.zone
  machine_type          = var.machine_type
  region                = var.region
  network               = module.vpc.network_id
  gce_ssh_user          = var.gce_ssh_user
  gce_ssh_pub_key_file  = var.gce_ssh_pub_key_file
  service_account_email = module.serviceaccount.service_account_email
  depends_on            = [module.vpc]
}

module "gke" {
  source                 = "../../modules/gke"
  project_id             = var.project_id
  env                    = var.env
  region                 = var.region
  node_machine_type      = var.node_machine_type
  node_disk_size         = var.node_disk_size
  min_node_count         = var.min_node_count
  max_node_count         = var.max_node_count
  vpc_id                 = module.vpc.network_id
  private_subnet_id      = module.vpc.subnets["${var.region}/${var.env}-private-subnet-1"].id
  image_type             = var.image_type
  disk_type              = var.disk_type
  node_version           = var.node_version
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  gke_version            = var.gke_version
  initial_node_count     = var.initial_node_count
  user_emails            = var.user_emails
  admin_network_cidr     = var.admin_network_cidr
  depends_on             = [module.vpc]
}
