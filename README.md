# Rufous PaaS — Terraform

Infrastructure-as-Code for the Rufous Platform-as-a-Service, built on Google Cloud Platform with Terraform.

This repository provisions the network, compute, data, and identity layers required to run the Rufous PaaS, organized as reusable modules and per-environment compositions.

## What's inside

```
.
├── modules/              # Reusable Terraform modules
│   ├── vpc/              # VPC, subnets, secondary ranges
│   ├── cloud-nat/        # Cloud NAT for private egress
│   ├── gke/              # Google Kubernetes Engine cluster
│   ├── instance/         # GCE VM instances
│   ├── gcs/              # Cloud Storage buckets
│   ├── gcr/              # Container registry
│   ├── redis/            # Memorystore for Redis
│   ├── mongodb/          # MongoDB Atlas cluster
│   └── serviceaccount/   # IAM service accounts & bindings
│
├── envs/                 # Environment-specific compositions
│   └── pass/             # PaaS environment (entry point)
│       ├── main.tf
│       ├── variables.tf
│       ├── provider.tf
│       ├── backend.tf
│       └── paas.variable.tfvars
│
├── tf-state-bucket.tf    # Remote state bucket bootstrap
├── CICD-PIPELINE.md      # CI/CD pipeline documentation
└── .gitignore
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) ≥ 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- A GCP project with billing enabled
- A GCP service account with permission to manage the resources above
- A MongoDB Atlas account and API key (for the `mongodb` module)

## Quick start

```bash
# 1. Authenticate to GCP
gcloud auth application-default login

# 2. Enter the environment you want to deploy
cd envs/pass

# 3. Initialize providers and remote state
terraform init

# 4. Review the plan
terraform plan -var-file=paas.variable.tfvars

# 5. Apply
terraform apply -var-file=paas.variable.tfvars
```

## Remote state

Terraform state is stored in a GCS bucket (see `backend.tf`). The bucket itself is bootstrapped from the root `tf-state-bucket.tf` and must exist before running `terraform init` inside an environment.

## Modules

Each module under `modules/` is self-contained and exposes its inputs via `variables.tf` and its outputs via `outputs.tf`. They are consumed from environment compositions in `envs/<env>/main.tf`.

## CI/CD

See [CICD-PIPELINE.md](./CICD-PIPELINE.md) for the deployment pipeline design.

## Security note

Do **not** commit service account keys, SSH private keys, or `.tfstate` files. Credentials belong in a secret manager (Secret Manager, Vault, or your CI's secret store), not in the repo.
