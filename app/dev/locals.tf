# Flatten core-infra remote state into locals; reference local.* below instead
# of repeating data.terraform_remote_state lookups.
locals {
  vpc_id             = data.terraform_remote_state.core.outputs.vpc_id
  vpc_cidr_block     = data.terraform_remote_state.core.outputs.vpc_cidr_block
  public_subnet_ids  = data.terraform_remote_state.core.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.core.outputs.private_subnet_ids
}
