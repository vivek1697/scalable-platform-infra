# Task security group: no direct inbound; egress anywhere (outbound via NAT).
resource "aws_security_group" "task" {
  name        = "${local.name}-task-sg"
  description = "ECS task SG for ${local.name}"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow the ALB to reach tasks on the container port (load-balanced services).
resource "aws_security_group_rule" "task_from_alb" {
  count = var.enable_load_balancer ? 1 : 0

  type                     = "ingress"
  description              = "ALB to task"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.task.id
  source_security_group_id = aws_security_group.alb[0].id
}

# ALB security group (load-balanced services only).
resource "aws_security_group" "alb" {
  count = var.enable_load_balancer ? 1 : 0

  name        = "${local.name}-alb-sg"
  description = "ALB SG for ${local.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet (demo; restrict to the CloudFront managed prefix list in prod)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
