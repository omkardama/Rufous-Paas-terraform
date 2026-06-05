# Create a GCS bucket
resource "google_storage_bucket" "gcs_bucket" {
  count         = length(var.bucket_names)
  name          = var.bucket_names[count.index]
  location      = var.region
  storage_class = var.storage_class
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }

  labels = {
    environment = var.env
    name        = var.bucket_names[count.index]
  }
}

# IAM Policy for Bucket Access
resource "google_storage_bucket_iam_member" "bucket_admin" {
  count = length(var.bucket_names)
  bucket = google_storage_bucket.gcs_bucket[count.index].name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.service_account_email}"
}
# Object-level permissions for the service account to view objects
resource "google_storage_bucket_iam_member" "object_viewer" {
  count  = length(var.bucket_names)
  bucket = google_storage_bucket.gcs_bucket[count.index].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email}"
}

# Object-level permissions for the service account to manage objects
resource "google_storage_bucket_iam_member" "object_admin" {
  count  = length(var.bucket_names)
  bucket = google_storage_bucket.gcs_bucket[count.index].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}
