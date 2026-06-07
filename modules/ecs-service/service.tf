resource "aws_ecs_service" "main" {
  name            = local.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.main[0].arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  # Autoscaling owns desired_count after creation; ignore drift on it.
  lifecycle {
    ignore_changes = [desired_count]
  }

  # Ensure the listener exists before registering targets.
  depends_on = [aws_lb_listener.http]
}
