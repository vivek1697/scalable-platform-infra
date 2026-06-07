output "queue_url" {
  description = "URL of the main jobs queue (web enqueues here)."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN of the main jobs queue (for IAM policies and worker scaling)."
  value       = aws_sqs_queue.main.arn
}

output "queue_name" {
  description = "Name of the main jobs queue (for CloudWatch queue-depth metrics)."
  value       = aws_sqs_queue.main.name
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}
