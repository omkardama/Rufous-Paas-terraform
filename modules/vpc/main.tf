## VPC Network
#resource "google_compute_network" "vpc_network" {
#  name                    = "${var.env}-vpc-network"
#  auto_create_subnetworks = false
#}
#
## Public Subnet
#resource "google_compute_subnetwork" "public_subnet" {
#  count         = length(var.public_subnets_cidr)
#  name          = "${var.env}-public-subnet-${count.index + 1}"
#  ip_cidr_range = element(var.public_subnets_cidr, count.index)
#  region        = var.region
#  network       = google_compute_network.vpc_network.id
#
#  # Disable Private Google Access
#  private_ip_google_access = false
#}
#
## Private Subnet
#resource "google_compute_subnetwork" "private_subnet" {
#  count         = length(var.private_subnets_cidr)
#  name          = "${var.env}-private-subnet-${count.index + 1}"
#  ip_cidr_range = element(var.private_subnets_cidr, count.index)
#  region        = var.region
#  network       = google_compute_network.vpc_network.id
#
#  # Enable Private Google Access
#  private_ip_google_access = true
#}
#
