variable "project" {
  description = "Project name, used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)."
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Must be dev, staging, or prod."
  }
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights (adds cost; off for the demo)."
  type        = bool
  default     = false
}

variable "capacity_providers" {
  description = "Fargate capacity providers available to the cluster."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider" {
  description = "Capacity provider used by the default strategy."
  type        = string
  default     = "FARGATE"
}
