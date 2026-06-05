variable "env" {
  description = "Environment name used as a prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Router and Cloud NAT"
  type        = string
}

variable "network" {
  description = "Name or self-link of the VPC network the Cloud Router attaches to"
  type        = string
}

variable "nat_subnetworks" {
  description = "List of subnetwork names (in this region) whose traffic should egress through Cloud NAT"
  type        = list(string)
}

variable "source_ip_ranges_to_nat" {
  description = "Per-subnetwork source ranges to NAT. ALL_IP_RANGES covers primary + secondary; use PRIMARY_IP_RANGE/LIST_OF_SECONDARY_IP_RANGES to scope tighter."
  type        = list(string)
  default     = ["ALL_IP_RANGES"]
}

variable "nat_ip_count" {
  description = "Number of static external IPs to reserve for the NAT. Whitelist these in MongoDB Atlas."
  type        = number
  default     = 1
}

variable "router_asn" {
  description = "Private ASN for the Cloud Router"
  type        = number
  default     = 64514
}

variable "min_ports_per_vm" {
  description = "Minimum NAT source ports allocated per VM"
  type        = number
  default     = 64
}

variable "enable_logging" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = true
}

variable "log_filter" {
  description = "Cloud NAT log filter: ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL"
  type        = string
  default     = "ERRORS_ONLY"
}
