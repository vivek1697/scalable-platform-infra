terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Demo: local state for simple create/destroy and easy cleanup.
  # State files are gitignored and never committed.
  backend "local" {}

  # --- Production-ready remote state (enable later) ---------------------------
  # For a real deployment, replace the local backend above with the S3 backend
  # below. Uses S3-native state locking (use_lockfile) and encryption. Left
  # commented out on purpose so the demo stays simple.
  #
  # backend "s3" {
  #   bucket       = "scalable-platform-infra-useast1-tf-dev"
  #   key          = "core-infra/live-dev.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
  # ---------------------------------------------------------------------------
}
