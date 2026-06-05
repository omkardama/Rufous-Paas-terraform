############################################
# GKE PRIVATE CLUSTER
############################################

resource "google_container_cluster" "gke_cluster_new" {
  name     = "rufous-ai-${var.env}"
  location = var.region

  network    = var.vpc_id
  subnetwork = var.private_subnet_id

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = var.gke_version

  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  ############################################
  # NETWORK POLICY (pod-to-pod isolation)
  ############################################
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  ############################################
  # BINARY AUTHORIZATION (image attestation)
  ############################################
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  ############################################
  # PRIVATE CLUSTER CONFIG
  ############################################
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false

    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  ############################################
  # MASTER AUTHORIZED NETWORKS
  ############################################
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.admin_network_cidr != "" ? [var.admin_network_cidr] : []

      content {
        cidr_block   = cidr_blocks.value
        display_name = "admin-network"
      }
    }
  }

  ############################################
  # IP ALLOCATION POLICY
  ############################################
  ip_allocation_policy {}

  ############################################
  # ADDONS
  ############################################
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }
  }

  ############################################
  # WORKLOAD IDENTITY
  ############################################
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ############################################
  # RELEASE CHANNEL
  ############################################
  release_channel {
    channel = "REGULAR"
  }

  ############################################
  # CLUSTER AUTOSCALING (NAP)
  ############################################
  # NAP disabled — region-wide scaling is handled by the node pool's
  # autoscaling block (total_min_node_count / total_max_node_count) below.
  cluster_autoscaling {
    enabled = false
  }

  ############################################
  # MAINTENANCE WINDOW
  ############################################
  maintenance_policy {
    recurring_window {
      start_time = "2026-01-01T02:00:00Z"
      end_time   = "2026-01-01T06:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }
}

############################################
# NODE POOL
############################################

resource "google_container_node_pool" "gke_node_pool_new" {
  name     = "node-pool-${var.env}"
  cluster  = google_container_cluster.gke_cluster_new.id
  location = var.region

  version = var.node_version

  # Sets the starting size at create time only. After that the autoscaler
  # owns the node count — do NOT set node_count here or it will drift on apply.
  initial_node_count = var.initial_node_count

  node_config {
    machine_type = var.node_machine_type

    disk_size_gb = var.node_disk_size
    disk_type    = var.disk_type

    image_type = var.image_type


    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["gke-node"]

    labels = {
      env = var.env
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Force pods through Workload Identity — blocks direct IMDS access
    # to the node service account from inside containers.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  ############################################
  # AUTOSCALING (region-wide totals across zones)
  ############################################
  autoscaling {
    total_min_node_count = var.min_node_count
    total_max_node_count = var.max_node_count
    location_policy      = "BALANCED"
  }

  ############################################
  # NODE MANAGEMENT
  ############################################
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

############################################
# FIREWALL RULES
############################################

resource "google_compute_firewall" "allow_node_https" {
  name    = "${var.env}-allow-node-https"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_tags = ["gke-node"]
}

############################################
# IAM ROLES
############################################

# TODO: Split var.user_emails into admin_user_emails and developer_user_emails.
# Granting container.admin to everyone is over-privileged; container.developer
# is enough for engineers who just deploy workloads.
resource "google_project_iam_member" "gke_admin" {
  for_each = toset(var.user_emails)

  project = var.project_id
  role    = "roles/container.admin"

  member = "user:${each.value}"
}

