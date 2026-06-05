########################################################################
# DEFAULT Variables
########################################################################
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "rufous-ai"

}

variable "region" {
  description = "The region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where resources will be created"
  type        = string
  default     = "us-central1-a"
}

variable "env" {
  type    = string
  default = "paas"
}


########################################################################
# GCS Variables
########################################################################
variable "bucket_names" {
  description = "List of bucket names"
  type        = list(string)
  default = [
    "rufous-ai-paas-bucket-1",
  ]
}


variable "storage_class" {
  description = "The storage class of the GCS bucket "
  type        = string
  default     = "STANDARD"
}


########################################################################
# VPC Variables
########################################################################
variable "vpc_routing_mode" {
  type    = string
  default = "REGIONAL"
}

variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default = {
    "paas-private-subnet-2" = [
      {
        ip_cidr_range = "10.60.0.0/14"
        range_name    = "ip-range-pods"
      },
      {
        ip_cidr_range = "10.64.0.0/20"
        range_name    = "ip-range-services"
      },
      {
        ip_cidr_range = "10.64.16.0/20"
        range_name    = "gke-dev-gke-cluster-services-82960522"
      },
      {
        ip_cidr_range = "10.68.0.0/14"
        range_name    = "gke-dev--gke-cluster-pods-82960522"
      }
    ]
  }
}


variable "public_subnet_cidr_block" {
  description = "Public subnet CIDR blocks by zone"
  type        = map(string)
  default = {
    1 = "10.25.0.0/22"
    2 = "10.25.4.0/22"
  }
}

variable "private_subnet_cidr_block" {
  description = "Private subnet CIDR blocks by zone"
  type        = map(string)
  default = {
    1 = "10.25.8.0/22"
    2 = "10.25.12.0/22"
  }
}


########################################################################
# Cloud NAT Variables
########################################################################
variable "nat_ip_count" {
  description = "Number of static external IPs to reserve for Cloud NAT (whitelist in MongoDB Atlas)"
  type        = number
  default     = 1
}


########################################################################
# Redis Variables
########################################################################
variable "redis_tier" {
  description = "Redis tier"
  type        = string
  default     = "BASIC"
}

variable "memory_size_gb" {
  description = "Redis memory size"
  type        = number
  default     = 1
}


########################################################################
# COMPUTE ENGINE Variables
########################################################################
variable "machine_type" {
  description = "Machine type for the Compute Engine instances"
  type        = string
  default     = "n2-standard-4"
}

variable "gce_ssh_user" {
  type    = string
  default = "sankar"

}

variable "gce_ssh_pub_key_file" {
  description = "Path to SSH public key"
  type        = string
  default     = "./gcp/instance.pub"
}

########################################################################
# GKE Variables
########################################################################
variable "node_machine_type" {
  description = "The machine type for the GKE nodes"
  type        = string
  default     = "e2-standard-4"
}
variable "node_disk_size" {
  description = "Disk size in GB for each node in the pool."
  type        = number
  default     = 100
}

variable "min_node_count" {
  description = "Minimum nodes in GKE node pool"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum nodes in GKE node pool"
  type        = number
  default     = 10
}
variable "admin_network_cidr" {
  description = "Admin CIDR range for SSH access"
  type        = string
}
variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master in a private GKE cluster"
  type        = string
}


variable "node_version" {
  description = "Kubernetes version for the nodes in the node pool"
  type        = string
}

variable "disk_type" {
  description = "Disk type for GKE nodes (e.g., pd-standard, pd-ssd)"
  type        = string
}

variable "image_type" {
  description = "Image type for GKE nodes (e.g., COS, UBUNTU)"
  type        = string
}

variable "gke_version" {
  description = "Minimum master version of the GKE cluster"
  type        = string
  default     = "1.34.4-gke.1193000"
}

variable "initial_node_count" {
  description = "Initial node count for GKE cluster"
  type        = number
  default     = 1
}

variable "user_emails" {
  description = "A list of user emails to grant IAM permissions."
  type        = list(string)
  default     = ["omkard@unifytech.com", "sankarc@unifytech.com"]

}

########################################################################
# GCR Variables
########################################################################
variable "repo_names" {
  description = "List of repository names to create in the Artifact Registry"
  type        = list(string)
  default     = ["paas-rufous-ai"]

}

variable "user_email" {
  description = "The email address to assign IAM roles for the repository"
  type        = string
}

########################################################################
# MongoDB Atlas Variables
########################################################################
variable "project_name" {
  description = "MongoDB Atlas project name"
  type        = string
  default     = "paas"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "paas"
}

variable "org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
  default     = "6a13e376ced441577b0cbf25"
}

variable "cluster_name" {
  description = "Name of the MongoDB cluster"
  type        = string
  default     = "rufous-cluster"
}

variable "cluster_tier" {
  description = "MongoDB cluster tier (M0, M10, M30, etc.)"
  type        = string
  default     = "M10"
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
variable "mongodbatlas_public_key" {
  description = "MongoDB Atlas Public API Key"
  type        = string
  sensitive   = true
}
variable "mongodbatlas_private_key" {
  description = "MongoDB Atlas Private API Key"
  type        = string
  sensitive   = true
}
