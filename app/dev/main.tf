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
