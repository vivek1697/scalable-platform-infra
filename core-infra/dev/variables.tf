variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Must be a valid AWS region (e.g., us-east-1)."
  }
}

variable "project" {
  description = "Project name, used for tagging and resource naming."
  type        = string
  default     = "scalable-platform-infra"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones the network spans."
  type        = number
  default     = 2
}
