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

variable "bucket_name" {
  description = "Override for the S3 bucket name. Defaults to {project}-{env}-frontend. Must be globally unique."
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Object served for requests to the root path."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 is the cheapest: US/Canada/Europe)."
  type        = string
  default     = "PriceClass_100"
}

variable "spa_routing" {
  description = "Map 403/404 responses to the root object so client-side routing works."
  type        = bool
  default     = true
}

variable "api_origin_domain_name" {
  description = "Optional API origin (e.g. the web ALB DNS name). When set, /api/* is routed to it. Empty disables the API behavior."
  type        = string
  default     = ""
}

variable "api_path_pattern" {
  description = "Path pattern routed to the API origin."
  type        = string
  default     = "/api/*"
}
