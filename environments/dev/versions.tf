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
  # below (plus a DynamoDB table for state locking). Left commented out on
  # purpose so the demo stays simple.
  #
  # backend "s3" {
  #   bucket         = "scalable-platform-infra-tfstate"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "scalable-platform-infra-tflock"
  #   encrypt        = true
  # }
  # ---------------------------------------------------------------------------
}
