## Create a bucket on gcp to store terraform state
resource "google_storage_bucket" "tfstate-bucket" {
  count         = terraform.workspace == "default" ? 1: 0
  name          = "rufous-tfstate"
  location      = var.region
  force_destroy = false
  public_access_prevention = "enforced"
  #soft_delete_policy = "7776000"

  # Enable Uniform Bucket-Level Access to restrict permissions to bucket level only
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
