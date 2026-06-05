variable "project_name" {
  description = "MongoDB Atlas project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the MongoDB cluster"
  type        = string
  default     = "rufous-cluster"
}

variable "cluster_tier" {
  description = "MongoDB cluster tier"
  type        = string
  default     = "M0"
}

variable "gcp_region" {
  description = "GCP region for MongoDB cluster"
  type        = string
  default     = "CENTRAL_US"
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "7.0"
}

variable "disk_size_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 100
}

variable "backup_enabled" {
  description = "Enable continuous backups"
  type        = bool
  default     = true
}

variable "auto_scaling_disk_enabled" {
  description = "Enable disk auto-scaling"
  type        = bool
  default     = true
}

variable "auto_scaling_compute_enabled" {
  description = "Enable compute auto-scaling"
  type        = bool
  default     = false
}

variable "gcp_project_id" {
  description = "GCP Project ID for VPC peering"
  type        = string
}

variable "gcp_network_name" {
  description = "GCP VPC network name"
  type        = string
}

variable "allowed_ip_addresses" {
  description = "MongoDB Atlas allowed CIDR blocks"
  type = list(object({
    cidr_block = string
    comment    = string
  }))
}

variable "database_users" {
  description = "Database users to create"
  type = list(object({
    username      = string
    role_name     = string
    database_name = string
  }))
}
variable "vpc_name" {
  description = "GCP VPC network name"
  type        = string
  default     = "paas-vpc"  # Change this to your actual VPC name
}
