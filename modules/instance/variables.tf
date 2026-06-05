variable "env" {}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "n1-standard-1"
}
variable "network" {}

variable "zone" {}

variable "region" {}

variable "gce_ssh_user" {}

variable "gce_ssh_pub_key_file" {}

variable "service_account_email" {}
