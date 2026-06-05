terraform {
  backend "gcs" {
    bucket      = "rufous-ai-tfstate"
    prefix      = "terraform/tfstate"
  }
}
