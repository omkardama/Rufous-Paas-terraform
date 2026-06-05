output "repo_names" {
  value = google_artifact_registry_repository.artifact_repo[*].repository_id
}
