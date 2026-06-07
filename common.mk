# common.mk — shared Terraform targets for a single layer directory.
#
# Included by each layer's Makefile (core-infra/dev/Makefile, app/dev/Makefile).
# Every target operates on the directory of the including Makefile — no cd
# needed, so you can `cd core-infra/dev && make init`.

THIS_MK   := $(lastword $(MAKEFILE_LIST))
TF        ?= terraform
REPO_ROOT ?= ../..

# Opt into non-interactive apply/destroy: make apply AUTO_APPROVE=1
ifdef AUTO_APPROVE
APPROVE := -auto-approve
else
APPROVE :=
endif

# Auto-load the repo-root .env (AWS creds) if present.
-include $(REPO_ROOT)/.env
export

.DEFAULT_GOAL := help

.PHONY: help check-aws fmt validate init plan apply destroy output clean

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(THIS_MK) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-9s\033[0m %s\n", $$1, $$2}'

check-aws: ## Fail fast if AWS credentials are not set
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
		echo "ERROR: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set."; \
		echo "       Export them, or fill $(REPO_ROOT)/.env (copy from .env.example)."; \
		exit 1; \
	fi

fmt: ## Format Terraform files in this layer
	$(TF) fmt -recursive

validate: ## Validate this layer (no backend/creds needed)
	$(TF) init -backend=false >/dev/null
	$(TF) validate

init: ## terraform init
	$(TF) init

plan: check-aws ## terraform plan
	$(TF) plan

apply: check-aws ## terraform apply
	$(TF) apply $(APPROVE)

destroy: check-aws ## terraform destroy
	$(TF) destroy $(APPROVE)

output: ## Show this layer's outputs
	$(TF) output

clean: ## Remove the local .terraform/ dir
	rm -rf .terraform
