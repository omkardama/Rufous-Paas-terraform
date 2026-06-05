output "service_account_email" {
  value = google_service_account.sa.email
}

output "service_account_key_file_path" {
  value       = local_file.service_account_key_file.filename
  description = "Path to the service account key file"
}
