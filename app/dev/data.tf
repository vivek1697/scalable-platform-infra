# Reads the core-infra (dev) outputs. Demo uses local state, so this points at
# the core-infra state file on disk. Switch to the S3 backend config when the
# production-ready remote state is enabled.
data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "${path.module}/../../core-infra/dev/terraform.tfstate"
  }
}
