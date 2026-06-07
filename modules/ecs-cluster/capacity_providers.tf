# Fargate capacity providers. FARGATE_SPOT is available for cost savings; the
# default strategy uses on-demand FARGATE so a baseline always runs.
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy {
    capacity_provider = var.default_capacity_provider
    base              = 1
    weight            = 100
  }
}
