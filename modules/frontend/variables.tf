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

variable "enable_api_origin" {
  description = "Route api_path_pattern to api_origin_domain_name (e.g. the web ALB). A static flag so plan-time count is known even when the ALB DNS name isn't."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_api_origin || (var.api_origin_domain_name != null && var.api_origin_domain_name != "")
    error_message = "api_origin_domain_name must be set when enable_api_origin is true."
  }
}

variable "api_origin_domain_name" {
  description = "API origin domain (e.g. the web ALB DNS name) used when enable_api_origin is true."
  type        = string
  default     = ""
}

variable "api_path_pattern" {
  description = "Path pattern routed to the API origin."
  type        = string
  default     = "/api/*"
}
