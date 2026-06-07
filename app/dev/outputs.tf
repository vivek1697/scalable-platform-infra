output "queue_url" {
  description = "URL of the main jobs queue."
  value       = module.queue.queue_url
}

output "queue_arn" {
  description = "ARN of the main jobs queue."
  value       = module.queue.queue_arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = module.queue.dlq_url
}

output "web_alb_dns_name" {
  description = "Public DNS name of the web ALB (CloudFront origin)."
  value       = module.web.alb_dns_name
}

output "frontend_url" {
  description = "CloudFront domain users hit for the static site."
  value       = "https://${module.frontend.distribution_domain_name}"
}

output "frontend_bucket_name" {
  description = "S3 bucket to upload the React build to."
  value       = module.frontend.bucket_name
}
