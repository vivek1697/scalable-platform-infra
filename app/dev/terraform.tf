terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Demo: local state, separate from core-infra to limit blast radius.
  # State files are gitignored and never committed.
  backend "local" {}

  # --- Production-ready remote state (enable later) ---------------------------
  # backend "s3" {
  #   bucket       = "scalable-platform-infra-useast1-tf-dev"
  #   key          = "app/live-dev.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
  # ---------------------------------------------------------------------------
}
