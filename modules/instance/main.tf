# Reserve a Static IP Address (This IP will NEVER change)
resource "google_compute_address" "static_ip" {
  name   = "${var.env}-static-ip"
  region = var.region
}

# Create the instance
resource "google_compute_instance" "instance" {
  name                      = "${var.env}-instance"
  machine_type              = var.machine_type
  zone                      = var.zone 
  can_ip_forward            = true
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    network    = var.network
    subnetwork = "${var.env}-public-subnet-1"
    access_config {
      nat_ip = google_compute_address.static_ip.address 
    }
  }
    ###  ENABLE OS LOGIN (IMPORTANT)
 metadata = {
    enable-oslogin = "FALSE"
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
        # ssh-keys       = "${var.gce_ssh_user}:${var.gce_ssh_pub_key_file}"

  }

  # lifecycle {
  #   create_before_destroy = true
  # }

  tags = [
    "http-server",
    "https-server",
    "ssh-access"
  ]

  labels = {
    name = "${var.env}-instance"
    env  = var.env
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

# Create a firewall rule to allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.env}-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-access"]
}

# Create a firewall rule to allow HTTP access
resource "google_compute_firewall" "http_firewall" {
  name    = "${var.env}-http"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Create a firewall rule to allow HTTPS access
resource "google_compute_firewall" "https_firewall" {
  name    = "${var.env}-https"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

