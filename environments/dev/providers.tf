provider "aws" {
  region = var.aws_region

  # Applied to every resource that supports tags.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
