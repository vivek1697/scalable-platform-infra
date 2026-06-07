# Internet-facing ALB fronting the service (CloudFront origin). Web only.
resource "aws_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name               = "${local.lb_name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb[0].id]
}

resource "aws_lb_target_group" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name        = "${local.lb_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # awsvpc Fargate tasks register by IP

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}
