# Create Artifact Registry Repositories
resource "google_artifact_registry_repository" "artifact_repo" {
  count         = length(var.repo_names)
  repository_id = var.repo_names[count.index]  
  format        = "DOCKER"
  description   = "Docker repository"

  labels = {
    name        = var.repo_names[count.index]
    environment = var.env
  }
  
  docker_config {
    immutable_tags = false
  }
}
resource "google_artifact_registry_repository_iam_policy" "admin_policy" {
  count      = length(var.repo_names)
  repository = google_artifact_registry_repository.artifact_repo[count.index].repository_id

  policy_data = jsonencode({
    bindings = [
      {
        role = "roles/artifactregistry.admin"
        members = compact([
          var.user_email != "" ? "user:${var.user_email}" : null,
          var.service_account_email != "" ? "serviceAccount:${var.service_account_email}" : null
        ])
      }
    ]
  })
}
