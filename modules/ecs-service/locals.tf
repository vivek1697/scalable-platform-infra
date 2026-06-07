locals {
  name = "${var.project}-${var.environment}-${var.service_name}"

  # ALB/target-group names are capped at 32 chars by AWS, so keep them short.
  lb_name = "${var.environment}-${var.service_name}"

  # Single container definition. portMappings only matter for ALB-fronted services.
  container_definition = merge(
    {
      name      = var.service_name
      image     = var.container_image
      essential = true
      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.service_name
        }
      }
    },
    var.enable_load_balancer ? {
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
    } : {}
  )

  container_definitions = jsonencode([local.container_definition])

  # Resource label the ALB request-count metric needs: "<alb_suffix>/<tg_suffix>".
  alb_resource_label = var.enable_load_balancer ? "${aws_lb.main[0].arn_suffix}/${aws_lb_target_group.main[0].arn_suffix}" : null
}
