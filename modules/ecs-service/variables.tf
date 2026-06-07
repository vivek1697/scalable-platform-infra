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

variable "service_name" {
  description = "Service role name, e.g. web or worker. Used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.service_name))
    error_message = "Must be lowercase kebab-case."
  }
}

# --- Cluster ---------------------------------------------------------------

variable "cluster_arn" {
  description = "ARN of the ECS cluster to run the service in."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for the autoscaling resource id)."
  type        = string
}

# --- Networking ------------------------------------------------------------

variable "vpc_id" {
  description = "VPC the service runs in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the ECS tasks."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (required when enable_load_balancer is true)."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable_load_balancer || length(var.public_subnet_ids) > 0
    error_message = "public_subnet_ids is required when enable_load_balancer is true."
  }
}

# --- Container -------------------------------------------------------------

variable "container_image" {
  description = "Container image to run. Defaults to a public placeholder for the demo."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  description = "Port the container listens on (used for the ALB target group)."
  type        = number
  default     = 80
}

variable "cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial desired task count (autoscaling manages it afterwards)."
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables to inject into the container."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log group retention for the service."
  type        = number
  default     = 14
}

# --- Load balancer ---------------------------------------------------------

variable "enable_load_balancer" {
  description = "Whether to front the service with an internet-facing ALB (web yes, worker no)."
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/"
}

# --- Autoscaling -----------------------------------------------------------

variable "min_capacity" {
  description = "Minimum number of tasks."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks."
  type        = number
  default     = 4
}

variable "scaling_metric" {
  description = "Autoscaling driver: 'alb' (request count per target) or 'sqs' (queue depth)."
  type        = string
  default     = "alb"

  validation {
    condition     = contains(["alb", "sqs"], var.scaling_metric)
    error_message = "scaling_metric must be 'alb' or 'sqs'."
  }

  validation {
    condition     = var.scaling_metric != "alb" || var.enable_load_balancer
    error_message = "scaling_metric 'alb' requires enable_load_balancer = true."
  }
}

variable "scaling_target_value" {
  description = "Target tracking value: requests-per-target (alb) or messages-per-task (sqs)."
  type        = number
  default     = 50
}

variable "scale_out_cooldown" {
  description = "Seconds to wait after a scale-out before another scale-out. Lower = more aggressive."
  type        = number
  default     = 300
}

variable "scale_in_cooldown" {
  description = "Seconds to wait after a scale-in before another scale-in."
  type        = number
  default     = 300
}

variable "scaling_sqs_queue_name" {
  description = "SQS queue name to scale on (required when scaling_metric is sqs)."
  type        = string
  default     = ""

  validation {
    condition     = var.scaling_metric != "sqs" || length(var.scaling_sqs_queue_name) > 0
    error_message = "scaling_sqs_queue_name is required when scaling_metric is sqs."
  }
}

# --- IAM -------------------------------------------------------------------

variable "attach_task_policy" {
  description = "Whether to attach task_role_policy_json to the task role. Use a static flag so plan-time count is known even when the policy references not-yet-created resources."
  type        = bool
  default     = false

  validation {
    condition     = !var.attach_task_policy || var.task_role_policy_json != null
    error_message = "task_role_policy_json must be set when attach_task_policy is true."
  }
}

variable "task_role_policy_json" {
  description = "IAM policy document (JSON) attached to the task role when attach_task_policy is true."
  type        = string
  default     = null
}
