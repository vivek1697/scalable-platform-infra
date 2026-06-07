# Makefile for scalable-platform-infra
#
# Two Terraform roots with strict ordering:
#   core-infra/dev  (network + ECS cluster)  ->  app/dev  (queue, services, frontend)
#
# Apply core before app; destroy app before core. The aggregate `apply` and
# `destroy` targets enforce this for you.
#
# AWS credentials are read from the environment by the AWS provider. Export
# them in your shell, or copy .env.example to .env (gitignored) and fill it in.

TF ?= terraform
CORE_DIR := core-infra/dev
APP_DIR  := app/dev

# Opt into non-interactive apply/destroy with `make apply AUTO_APPROVE=1`.
ifdef AUTO_APPROVE
APPROVE := -auto-approve
else
APPROVE :=
endif

# Auto-load a gitignored .env (if present) and export it to recipe commands.
-include .env
export

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

.PHONY: check-aws
check-aws: ## Fail fast if AWS credentials are not set
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
		echo "ERROR: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set."; \
		echo "       Export them in your shell, or copy .env.example to .env and fill it in."; \
		exit 1; \
	fi

# ---------------------------------------------------------------------------
# Quality (no AWS credentials required)
# ---------------------------------------------------------------------------

.PHONY: fmt
fmt: ## Format all Terraform files
	$(TF) fmt -recursive

.PHONY: validate
validate: ## Validate both roots (no backend/creds needed)
	cd $(CORE_DIR) && $(TF) init -backend=false >/dev/null && $(TF) validate
	cd $(APP_DIR)  && $(TF) init -backend=false >/dev/null && $(TF) validate

# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------

.PHONY: init init-core init-app
init: init-core init-app ## Init both roots

init-core: ## Init core-infra/dev
	cd $(CORE_DIR) && $(TF) init

init-app: ## Init app/dev
	cd $(APP_DIR) && $(TF) init

# ---------------------------------------------------------------------------
# Plan
# ---------------------------------------------------------------------------

.PHONY: plan plan-core plan-app
plan: plan-core plan-app ## Plan both (core then app)

plan-core: check-aws ## Plan core-infra/dev
	cd $(CORE_DIR) && $(TF) plan

plan-app: check-aws ## Plan app/dev (requires core applied first)
	cd $(APP_DIR) && $(TF) plan

# ---------------------------------------------------------------------------
# Apply (core -> app)
# ---------------------------------------------------------------------------

.PHONY: apply apply-core apply-app
apply: apply-core apply-app ## Apply core then app (correct order)

apply-core: check-aws ## Apply core-infra/dev
	cd $(CORE_DIR) && $(TF) apply $(APPROVE)

apply-app: check-aws ## Apply app/dev
	cd $(APP_DIR) && $(TF) apply $(APPROVE)

# ---------------------------------------------------------------------------
# Destroy (app -> core, reverse order)
# ---------------------------------------------------------------------------

.PHONY: destroy destroy-app destroy-core
destroy: destroy-app destroy-core ## Destroy app then core (reverse order)

destroy-app: check-aws ## Destroy app/dev
	cd $(APP_DIR) && $(TF) destroy $(APPROVE)

destroy-core: check-aws ## Destroy core-infra/dev
	cd $(CORE_DIR) && $(TF) destroy $(APPROVE)

# ---------------------------------------------------------------------------
# Outputs / cleanup
# ---------------------------------------------------------------------------

.PHONY: output-core output-app
output-core: ## Show core-infra/dev outputs
	cd $(CORE_DIR) && $(TF) output

output-app: ## Show app/dev outputs
	cd $(APP_DIR) && $(TF) output

.PHONY: clean
clean: ## Remove local .terraform/ dirs (keeps state and lockfiles)
	rm -rf $(CORE_DIR)/.terraform $(APP_DIR)/.terraform
