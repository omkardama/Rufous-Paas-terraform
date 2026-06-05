terraform {
  backend "gcs" {
    bucket = "rufous-ai-paas-tfstate"
    prefix = "terraform/tfstate/paas"
  }
}
