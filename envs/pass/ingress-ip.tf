resource "google_compute_global_address" "ingress_ip" {
    name = "rufous-ingress-ip"
  }
  
  output "ingress_ip" {
    value       = google_compute_global_address.ingress_ip.address
    description = "Static IP for the rufous.com Ingress — point all DNS A records here"
  }