# Application infrastructure (dev) — separate state from core-infra.
#
# App modules get wired in here, consuming the network via locals sourced from
# core-infra remote state (see data.tf / locals.tf), e.g.:
#
#   module "web" {
#     source             = "../../modules/ecs-service"
#     project            = var.project
#     environment        = var.environment
#     vpc_id             = local.vpc_id
#     private_subnet_ids = local.private_subnet_ids
#     public_subnet_ids  = local.public_subnet_ids
#   }
#
# Build order (DB out of scope for the demo):
#   ecs-cluster -> queue -> ecs-service (web) -> ecs-service (worker) -> frontend

module "queue" {
  source = "../../modules/queue"

  project     = var.project
  environment = var.environment
}

# Web: ALB-fronted Fargate service, scales on ALB request count. Enqueues jobs.
module "web" {
  source = "../../modules/ecs-service"

  project      = var.project
  environment  = var.environment
  service_name = "web"

  cluster_arn  = local.ecs_cluster_arn
  cluster_name = local.ecs_cluster_name

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  container_port = 80
  desired_count  = 1

  enable_load_balancer = true
  scaling_metric       = "alb"
  scaling_target_value = 50
  min_capacity         = 1
  max_capacity         = 4

  task_role_policy_json = data.aws_iam_policy_document.web_queue_access.json

  environment_variables = {
    JOBS_QUEUE_URL = module.queue.queue_url
  }
}

# Worker: no ALB, scales on SQS queue depth. Consumes jobs.
module "worker" {
  source = "../../modules/ecs-service"

  project      = var.project
  environment  = var.environment
  service_name = "worker"

  cluster_arn  = local.ecs_cluster_arn
  cluster_name = local.ecs_cluster_name

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  desired_count = 1

  enable_load_balancer   = false
  scaling_metric         = "sqs"
  scaling_sqs_queue_name = module.queue.queue_name
  scaling_target_value   = 100
  min_capacity           = 1
  max_capacity           = 6

  task_role_policy_json = data.aws_iam_policy_document.worker_queue_access.json

  environment_variables = {
    JOBS_QUEUE_URL = module.queue.queue_url
  }
}

# Frontend: CloudFront + S3 static React app. Routes /api/* to the web ALB.
module "frontend" {
  source = "../../modules/frontend"

  project     = var.project
  environment = var.environment

  api_origin_domain_name = module.web.alb_dns_name
}
