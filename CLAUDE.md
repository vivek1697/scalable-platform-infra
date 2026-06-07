# CLAUDE.md

Context for future work in this repo.

## Project

Terraform IaC **demo** that provisions an **auto-scaling ECS Fargate platform on AWS**.
Layered into core (shared) and app infrastructure, designed to be multi-region ready.
See `Infra_Diagram/infra_diagram.jpg` for the reference architecture.

## Current state

This is an early scaffold. As of now the repo contains only:

- `README.md` — one-line project description
- `Infra_Diagram/infra_diagram.jpg` — target architecture diagram
- `.gitignore` — standard Terraform ignores (state, `.terraform/`, `*.tfvars`)

There is **no Terraform code yet**. Most future work is building it out from scratch
to match the diagram.

## Demo scope

This is a demo, so we intentionally keep it lean:

- **No database** is provisioned — Aurora PostgreSQL + RDS Proxy are **out of scope**.
  Build the compute/queue/network path only; treat data as a future addition.
- Local state only (see Conventions) for simple create/cleanup.

## Architecture (from the diagram)

**Edge / frontend**
- Static React frontend served via **CloudFront + S3**.
- User requests flow CloudFront → **Application Load Balancer** (public subnets).

**Compute (private subnets, 2 AZ)**
- **ECS Fargate — web**: scales on ALB request count. Serves API traffic, enqueues heavy jobs.
- **SQS**: queue for heavy/async jobs (web enqueues, worker consumes).
- **ECS Fargate — worker**: scales on SQS queue depth. Polls and processes jobs.

**Data** _(out of scope for this demo — see Demo scope below)_
- **RDS Proxy** for connection pooling, fronting…
- **Aurora PostgreSQL**: primary (writes) + read replica (reads).

**Networking**
- **VPC** spanning **2 AZs**, with public + private subnets.
- **ALB** and **NAT Gateway + EIP** live in public subnets.
- **NAT Gateway** gives a **fixed egress IP** so outbound calls to **partner systems**
  (whitelisted external APIs/DBs) come from a stable address.

## Layout

State is split into two independent root configs to **limit blast radius**:
a bad `apply` in the app layer can never touch the VPC/networking in core-infra.

```
modules/              # reusable building blocks
  network/            #   VPC, public/private subnets (2 AZ), NAT + EIP, routing  [built]
  frontend/           #   CloudFront + S3 for the static React app
  ecs-cluster/        #   ECS cluster + Fargate capacity providers  [built]
  ecs-service/        #   reusable Fargate service (task def, ALB wiring, auto-scaling)
  queue/              #   SQS queue(s)
core-infra/           # CORE layer — shared foundation, own state
  dev/                #   provisions network, exports VPC/subnet outputs  [built]
app/                  # APP layer — application resources, own state
  dev/                #   reads core-infra outputs via terraform_remote_state
```

- **Core** (`core-infra/`) = `network` + `ecs-cluster`. Foundation.
- **App** (`app/`) = web `ecs-service`, worker `ecs-service`, `queue`, `frontend`.
- Each layer's `dev/` is a separate Terraform root with its own state. The app
  layer consumes core outputs via `terraform_remote_state` (see `app/dev/data.tf`).
- `database/` module is intentionally omitted (DB out of scope — see Demo scope).

## File conventions (per .claude/rules/infrastructure)

- `terraform.tf` — backend + `required_providers` + `required_version`
- `provider.tf` — provider config (root/live layer only; never inside modules)
- `variables.tf` / `outputs.tf` / `locals.tf` (ALL locals here) / `data.tf` (remote state)
- Modules: one resource type per file (`vpc.tf`, `subnets.tf`, `gateways.tf`, `routes.tf`)
- Add `validation {}` blocks on constrained variables; tag via provider `default_tags`.

## Conventions

- Run `terraform fmt` and `terraform validate` before committing.
- Pin provider and Terraform versions (`required_providers` / `required_version`).
- **State (demo):** use **local state** — keeps create/destroy simple and cleanup easy.
  Do **not** configure an S3 backend or DynamoDB lock for the demo. Still include the
  S3 + DynamoDB backend resources/config in the code but **commented out**, with a note
  that it's the production-ready setup to enable later. Never commit state files.
- Keep secrets and env values in `*.tfvars` (already gitignored); don't hardcode them.
- Tag resources consistently (e.g. `Project`, `Environment`, `ManagedBy = terraform`).
- Auto-scaling: web scales on ALB request count, worker scales on SQS queue depth.

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
