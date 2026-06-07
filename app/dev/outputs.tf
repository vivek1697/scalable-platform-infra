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
