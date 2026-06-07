# Core infrastructure (dev) — shared foundation with its own state.
# Kept separate from the app layer to limit blast radius: an app-layer
# apply can never touch the VPC/networking provisioned here.

module "network" {
  source = "../../modules/network"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  project     = var.project
  environment = var.environment
}
