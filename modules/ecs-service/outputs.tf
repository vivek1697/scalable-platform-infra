output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.main.name
}

output "task_role_arn" {
  description = "ARN of the task role (container identity)."
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the task role."
  value       = aws_iam_role.task.name
}

output "execution_role_arn" {
  description = "ARN of the task execution role."
  value       = aws_iam_role.execution.arn
}

output "task_security_group_id" {
  description = "Security group ID attached to the tasks."
  value       = aws_security_group.task.id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (null for non-load-balanced services)."
  value       = try(aws_lb.main[0].dns_name, null)
}

output "alb_arn" {
  description = "ARN of the ALB (null for non-load-balanced services)."
  value       = try(aws_lb.main[0].arn, null)
}

output "target_group_arn" {
  description = "ARN of the ALB target group (null for non-load-balanced services)."
  value       = try(aws_lb_target_group.main[0].arn, null)
}
