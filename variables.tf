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
  default     = "asia-south1"
}

variable "zone" {
  description = "The zone where resources will be created"
  type        = string
  default     = "asia-south1-a"
}

variable "env" {
  type    = string
  default = "prod" 
}


########################################################################
# GCS Variables
########################################################################
variable "bucket_names" {
  description = "List of bucket names"
  type        = list(string)
  default = [
  "rufous-ai-prod-bucket-1",
]
}


variable "storage_class" {
  description = "The storage class of the GCS bucket "
  type        = string
  default     = "STANDARD"
}


########################################################################
# Pub/Sub Variables
########################################################################
variable "ack_deadline_seconds" {
  description = "Pub/Sub ack deadline in seconds"
  type        = number
  default     = 30
}


########################################################################
# VPC Variables
########################################################################
#variable "public_subnets_cidr" {
#  description = "CIDR range for the public subnet"
#  type        = list
#}
#
#variable "private_subnets_cidr" {
#  description = "CIDR range for the private subnet"
#  type        = list
#}

variable "vpc_routing_mode" {
  type = string
  default = "REGIONAL"
}

variable "secondary_ranges" {
  type        = map(list(object({ range_name = string, ip_cidr_range = string })))
  description = "Secondary ranges that will be used in some of the subnets"
  default = {
    "prod-private-subnet-2" = [
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
        range_name    = "gke-prod-gke-cluster-services-82960522"
      },
      {
        ip_cidr_range = "10.68.0.0/14"
        range_name    = "gke-prod--gke-cluster-pods-82960522"
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


variable "default_igw_route_tags" {
  type    = list
  default = ["egress-igw"]
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
# variable "instance_count" {
#   description = "Number of instances to create"
#   type        = number
#   default     = 1
# }

variable "machine_type" {
  description = "Machine type for the Compute Engine instances"
  type        = string
  default     = "n2-standard-4 "
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
}
variable "node_disk_size" {
  description = "Disk size in GB for each node in the pool."
  type        = number
  default     = 100  
}

variable "min_node_count" {
  description = "Minimum nodes in GKE node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes in GKE node pool"
  type        = number
  default     = 3
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
}

variable "initial_node_count" {
  description = "Initial node count for GKE cluster"
  type        = number
  default     = 1
}

variable "gke_roles" {
  description = "A list of IAM roles for GKE users."
  type        = list(string)
  default     = ["roles/container.admin", "roles/container.developer,",
"roles/viewer"]
}
# variable "node_count" {
#   description = "Node count for other resources"
#   type        = number
#   default     = 1
# }
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
  default     = ["rufous-ai"]

}

variable "user_email" {
  description = "The email address to assign IAM roles for the repository"
  type        = string
}
# ########################################################################
# # CORE VARIABLES
# ########################################################################
# variable "project_id" {
#   description = "The ID of the GCP project"
#   type        = string
# }

# variable "region" {
#   description = "The region where resources will be created"
#   type        = string
# }

# variable "zone" {
#   description = "The zone where resources will be created"
#   type        = string
# }

# variable "env" {
#   description = "Environment name (prod/dev/stage)"
#   type        = string
# }

# ########################################################################
# # GCS VARIABLES
# ########################################################################
# variable "bucket_names" {
#   description = "List of bucket names"
#   type        = list(string)
# }

# variable "storage_class" {
#   description = "The storage class of the GCS bucket"
#   type        = string
# }

# ########################################################################
# # PUB/SUB VARIABLES
# ########################################################################
# variable "ack_deadline_seconds" {
#   description = "Pub/Sub ack deadline in seconds"
#   type        = number
#   default     = 30
# }

# ########################################################################
# # VPC VARIABLES
# ########################################################################
# variable "vpc_routing_mode" {
#   description = "VPC routing mode"
#   type        = string
#   default     = "REGIONAL"
# }

# variable "public_subnet_cidr_block" {
#   description = "Public subnet CIDR blocks by zone"
#   type        = map(string)
# }

# variable "private_subnet_cidr_block" {
#   description = "Private subnet CIDR blocks by zone"
#   type        = map(string)
# }

# variable "secondary_ranges" {
#   description = "Secondary IP ranges for GKE subnets"
#   type = map(list(object({
#     range_name    = string
#     ip_cidr_range = string
#   })))
# }

# variable "default_igw_route_tags" {
#   description = "Default route tags"
#   type        = list(string)
#   default     = ["egress-igw"]
# }

# ########################################################################
# # REDIS VARIABLES
# ########################################################################
# variable "redis_tier" {
#   description = "Redis tier"
#   type        = string
# }

# variable "memory_size_gb" {
#   description = "Redis memory size in GB"
#   type        = number
# }

# ########################################################################
# # COMPUTE ENGINE VARIABLES
# ########################################################################
# variable "machine_type" {
#   description = "Machine type for Compute Engine"
#   type        = string
# }

# variable "gce_ssh_user" {
#   description = "SSH username for Compute Engine"
#   type        = string
# }

# variable "gce_ssh_pub_key_file" {
#   description = "Path to SSH public key"
#   type        = string
# }

# ########################################################################
# # GKE VARIABLES
# ########################################################################
# variable "gke_version" {
#   description = "GKE control plane version"
#   type        = string
# }

# variable "node_version" {
#   description = "GKE node version"
#   type        = string
# }

# variable "node_machine_type" {
#   description = "Machine type for GKE nodes"
#   type        = string
# }

# variable "node_disk_size" {
#   description = "Disk size for GKE nodes"
#   type        = number
#   default     = 100
# }

# variable "disk_type" {
#   description = "Disk type for GKE nodes"
#   type        = string
# }

# variable "image_type" {
#   description = "Node image type"
#   type        = string
# }

# variable "initial_node_count" {
#   description = "Initial node count"
#   type        = number
#   default     = 1
# }

# variable "min_node_count" {
#   description = "Minimum node count"
#   type        = number
# }

# variable "max_node_count" {
#   description = "Maximum node count"
#   type        = number
# }

# variable "admin_network_cidr" {
#   description = "Admin CIDR for SSH access"
#   type        = string
# }

# variable "master_ipv4_cidr_block" {
#   description = "CIDR block for GKE master"
#   type        = string
# }

# ########################################################################
# # IAM VARIABLES
# ########################################################################
# variable "user_emails" {
#   description = "User emails for IAM bindings"
#   type        = list(string)
# }

# variable "gke_roles" {
#   description = "IAM roles for GKE users"
#   type        = list(string)
# }

# ########################################################################
# # ARTIFACT REGISTRY (GCR)
# ########################################################################
# variable "repo_names" {
#   description = "Artifact Registry repository names"
#   type        = list(string)
# }

# variable "user_email" {
#   description = "Email to assign Artifact Registry IAM roles"
#   type        = string
# }


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
    username     = string
    password     = string
    role_name    = string
    database_name = string
  }))
  default = []
}