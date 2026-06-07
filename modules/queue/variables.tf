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

variable "queue_name" {
  description = "Short queue purpose, used in the queue name (e.g. jobs)."
  type        = string
  default     = "jobs"
}

variable "visibility_timeout_seconds" {
  description = "How long a message is hidden after a worker picks it up. Should exceed the worker's max processing time."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long messages are retained in the main queue."
  type        = number
  default     = 345600 # 4 days
}

variable "max_receive_count" {
  description = "Failed deliveries before a message is moved to the dead-letter queue."
  type        = number
  default     = 5
}

variable "dlq_message_retention_seconds" {
  description = "How long messages are retained in the dead-letter queue."
  type        = number
  default     = 1209600 # 14 days
}
