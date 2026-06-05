resource "google_compute_address" "nat" {
  count   = var.nat_ip_count
  project = var.project_id
  region  = var.region
  name    = "${var.env}-nat-ip-${count.index + 1}"

  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

resource "google_compute_router" "router" {
  project = var.project_id
  region  = var.region
  name    = "${var.env}-nat-router"
  network = var.network

  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  region  = var.region
  name    = "${var.env}-cloud-nat"
  router  = google_compute_router.router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.nat[*].self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = toset(var.nat_subnetworks)
    content {
      name                    = subnetwork.value
      source_ip_ranges_to_nat = var.source_ip_ranges_to_nat
    }
  }

  min_ports_per_vm                    = var.min_ports_per_vm
  enable_endpoint_independent_mapping = false

  log_config {
    enable = var.enable_logging
    filter = var.log_filter
  }
}
