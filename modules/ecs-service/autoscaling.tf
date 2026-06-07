resource "aws_appautoscaling_target" "main" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Web: scale on ALB request count per target.
resource "aws_appautoscaling_policy" "alb" {
  count = var.scaling_metric == "alb" ? 1 : 0

  name               = "${local.name}-alb-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = local.alb_resource_label
    }

    target_value       = var.scaling_target_value
    scale_out_cooldown = var.scale_out_cooldown
    scale_in_cooldown  = var.scale_in_cooldown
  }
}

# Worker: scale on SQS queue depth (messages visible per task).
resource "aws_appautoscaling_policy" "sqs" {
  count = var.scaling_metric == "sqs" ? 1 : 0

  name               = "${local.name}-sqs-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = var.scaling_sqs_queue_name
      }
    }

    target_value       = var.scaling_target_value
    scale_out_cooldown = var.scale_out_cooldown
    scale_in_cooldown  = var.scale_in_cooldown
  }
}
