output "instance_pub_ip" {
  value = google_compute_instance.instance.network_interface[0].access_config[0].nat_ip
  description = "The external IP address of the instance"
}

output "instance_pvt_ip" {
  value = google_compute_instance.instance.network_interface[0].network_ip
}
