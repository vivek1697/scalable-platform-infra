# CLAUDE.md

Context for future work in this repo.

## Project

Terraform IaC **demo** that provisions an **auto-scaling ECS Fargate service on AWS**.
Layered into core (shared) and app infrastructure, designed to be multi-region ready.

## Current state

This is an early scaffold. As of now the repo contains only:

- `README.md` — one-line project description
- `.gitignore` — standard Terraform ignores (state, `.terraform/`, `*.tfvars`)

There is **no Terraform code yet**. Most future work is building it out from scratch.

## Target layout

Proposed structure to grow into (not built yet):

```
modules/            # reusable building blocks
  network/          #   VPC, subnets, routing, security groups
  ecs-cluster/      #   ECS cluster + Fargate capacity
  ecs-service/      #   task def, service, ALB, auto-scaling policies
environments/       # per-env, per-region root configs that wire modules together
  dev/
  prod/
```

- **Core** = `network` + `ecs-cluster` (shared foundation).
- **App** = `ecs-service` (the scalable workload).
- Each `environments/*` directory is its own Terraform root with its own state.

## Conventions

- Run `terraform fmt` and `terraform validate` before committing.
- Pin provider and Terraform versions (`required_providers` / `required_version`).
- Use remote state (S3 backend + DynamoDB lock) per environment — never commit state.
- Keep secrets and env values in `*.tfvars` (already gitignored); don't hardcode them.
- Tag resources consistently (e.g. `Project`, `Environment`, `ManagedBy = terraform`).

## Commands

```bash
terraform fmt -recursive      # format
terraform validate            # sanity-check config
terraform plan                # preview changes
terraform apply               # apply (demo — confirm before touching real AWS)
```

## Guardrails

- This is a **demo**: do not `apply` against a real AWS account without explicit confirmation.
- Keep credentials and secrets out of version control.
