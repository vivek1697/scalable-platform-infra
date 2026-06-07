# Dev environment root.
#
# Modules get wired in here as they are built, e.g.:
#
#   module "network" {
#     source      = "../../modules/network"
#     project     = var.project
#     environment = var.environment
#   }
#
# Build order (per the architecture diagram, DB out of scope for the demo):
#   network -> ecs-cluster -> queue -> ecs-service (web) -> ecs-service (worker) -> frontend
