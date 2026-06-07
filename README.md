# scalable-platform-infra

Terraform IaC for an auto-scaling **ECS Fargate** platform on AWS. It is split
into two layers — **core** (VPC, subnets, NAT, ECS cluster) and **app** (queue,
web and worker services, frontend) — each with its own state. See
`Infra_Diagram/infra_diagram.jpg` for the architecture.

This is a demo. It runs on **local state** (no S3 backend) so it is easy to spin
up and tear down.

> **Design rationale:** the full architecture, design decisions, and trade-offs
> behind this build are written up in **`Design document.pdf`** — read that for
> the "why". This README covers the "how".

---

## What you need first

You need an **AWS account** and credentials, plus a few command-line tools.

| Tool | Why | Install |
|------|-----|---------|
| Terraform (>= 1.9) | Provision the infrastructure | via `brew bundle` |
| AWS CLI v2 | Deploy + run the demo commands | official installer (see below) |
| hey | Generate HTTP load for the scaling demo | via `brew bundle` |
| make, git | Run commands / version control | preinstalled on macOS |

Install Terraform and hey with the included `Brewfile`:

```bash
brew bundle
```

**AWS CLI** — install the official AWS CLI v2 package, **not** the Homebrew one.
The Homebrew `awscli` depends on Homebrew's Python and breaks when Python is
upgraded (you'll see a `pyexpat` / `libexpat` symbol error). The official
package bundles its own Python and avoids this:

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg
aws --version   # should print aws-cli/2.x
```

If you previously installed it via Homebrew, remove that first with
`brew uninstall awscli`.

### AWS credentials

The AWS provider reads credentials from your environment. The easiest way for
the demo is a `.env` file at the repo root (it is gitignored):

```bash
cp .env.example .env
# then edit .env and fill in AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

The Makefiles load `.env` automatically.

---

## Project layout

```
core-infra/dev/   # Layer 1: VPC, subnets, NAT, ECS cluster   (apply first)
app/dev/          # Layer 2: SQS, web + worker services, frontend
modules/          # reusable building blocks used by both layers
```

The app layer reads the core layer's outputs, so **core must be applied before
app**. The **worker** service is provisioned but runs the placeholder image —
the web → SQS → worker path is wired structurally, not exercised by a real
application.

---

## Deploy

You can use `make` (recommended) or plain `terraform`. Each layer has its own
Makefile. Run everything below **from the repo root** — each step is wrapped in
a subshell `( … )`, so the directory change is local to that step and you always
return to the repo root (copy-paste the whole sequence safely).

```bash
# Run from the repo root. Core layer first, then app.
( cd core-infra/dev && make init && make plan && make apply )
( cd app/dev        && make init && make plan && make apply )
```

When the app layer finishes, see the important URLs:

```bash
( cd app/dev && make output )   # web_alb_dns_name, frontend_url, queue_url, ...
```

To tear everything down, destroy in the **reverse** order (app first, then core):

```bash
# Run from the repo root.
( cd app/dev        && make destroy )
( cd core-infra/dev && make destroy )
```

---

## Demo: watch the web service scale up

The web service runs behind an Application Load Balancer and **adds more tasks
automatically when it gets busy** (target: ~10 requests per task). This demo
sends traffic at it and watches the task count grow.

Make sure the app layer is applied first (`cd app/dev && make apply`).

### Step 1 — load credentials and set some shortcuts

Run from the repo root. The first line loads your AWS credentials from `.env`
into this shell — the `aws` CLI needs them. (The Makefiles load `.env`
automatically, but a direct `aws` command in your terminal does not.)

```bash
set -a; source .env; set +a        # load AWS creds (and region) from .env
aws sts get-caller-identity         # quick check — prints your account/ARN

export AWS_REGION=${AWS_REGION:-us-east-1}
export CLUSTER=$(terraform -chdir=core-infra/dev output -raw ecs_cluster_name)
# SERVICE follows the module naming convention <project>-<env>-web; it isn't a
# Terraform output, so it's set literally here.
export SERVICE=scalable-platform-infra-dev-web
export ALB=$(terraform -chdir=app/dev output -raw web_alb_dns_name)
```

### Step 2 — check autoscaling is set up

```bash
aws application-autoscaling describe-scaling-policies \
  --service-namespace ecs --resource-id service/$CLUSTER/$SERVICE \
  --query 'ScalingPolicies[0].TargetTrackingScalingPolicyConfiguration'
```

You should see `TargetValue: 10.0` and `ScaleOutCooldown: 60`.

### Step 3 — watch the task count (Terminal A)

This refreshes every 10 seconds. Leave it running.

```bash
while true; do clear; date; \
  aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
    --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}' \
    --output table; \
  echo "recent scaling activity:"; \
  aws application-autoscaling describe-scaling-activities --service-namespace ecs \
    --resource-id service/$CLUSTER/$SERVICE \
    --query 'ScalingActivities[0:2].Description' --output text; \
  sleep 10; done
```

### Step 4 — send traffic (Terminal B)

```bash
hey -z 4m -c 50 http://$ALB/
```

(no `hey`? macOS has ApacheBench: `ab -t 240 -c 50 -n 1000000 http://$ALB/`)

### What you will see

1. It starts with **1 task** running.
2. About **2–3 minutes** after the load starts, the alarm trips and the task
   count goes **1 → 2 → 3 → 4**. You'll see new tasks as `pending`, then
   `running`.
3. The activity log prints messages like *"Setting desired count to 3."*
4. When you stop the load, after a few minutes it scales back down to 1.

### If nothing scales

- The first scale-up takes ~2–3 minutes — be patient.
- If the count never moves, the tasks may be unhealthy. Check the load balancer
  targets:
  ```bash
  aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
    --query 'services[0].events[0:5].message'
  ```

---

## Inspect what you built

The scaling demo above is the main "see it work" path. To poke at the rest of
what was created (run with credentials loaded — see the demo's Step 1):

```bash
# the important values (URLs, names, queue)
terraform -chdir=app/dev output
terraform -chdir=core-infra/dev output

# open the static site / hit the web service
open "$(terraform -chdir=app/dev output -raw frontend_url)"
curl -I "http://$(terraform -chdir=app/dev output -raw web_alb_dns_name)"

# ECS services + running tasks
aws ecs describe-services --cluster $CLUSTER --services $SERVICE \
  --query 'services[0].{desired:desiredCount,running:runningCount}'

# live application logs
aws logs tail /ecs/scalable-platform-infra-dev-web --follow

# the jobs queue
aws sqs get-queue-attributes \
  --queue-url "$(terraform -chdir=app/dev output -raw queue_url)" \
  --attribute-names ApproximateNumberOfMessages
```

---

## Assumptions & shortcuts

Built as a time-boxed demo, so several things were deliberately simplified:

- **State:** local state on disk — **no S3 backend and no locking**
  (DynamoDB / S3-native). Fine for one operator, unsafe for a team. The S3
  backend is stubbed (commented out) in each layer's `terraform.tf`.
- **Minimal scope:** just enough to show an auto-scaling ECS platform. **No
  database** — Aurora + RDS Proxy are in the diagram but out of scope.
- **Placeholder app:** services run a public **nginx image**, not a real
  application, so there is no build/push step.
- **Little observability:** only basic CloudWatch log groups; Container Insights
  is off, and there are no dashboards, custom alarms, metrics, or tracing.
- **Minimal security/access:** task roles are scoped to the SQS queue plus a
  managed execution role; **no secrets manager, no WAF, no TLS** (HTTP only),
  and the ALB is open to `0.0.0.0/0:80` rather than the CloudFront prefix list.
  Auth is a single IAM user via `.env`.
- **Networking:** a **single NAT Gateway** (not one per AZ).
- **Demo-tuned autoscaling:** aggressive values (target 10 requests/task, 60s
  cooldowns), not production-realistic.
- **One env, one region:** `dev` only — no `prod`, no multi-region.
- **No CI/CD.**

---

## What I'd do next

With more time I'd build this out end-to-end and cover the bases left out above:

- **Remote state + locking:** move each layer to an S3 backend with locking
  (already stubbed in `terraform.tf`).
- **Data layer:** add Aurora PostgreSQL + RDS Proxy (private subnets, encrypted,
  credentials in Secrets Manager).
- **Observability:** CloudWatch dashboards + alarms, Container Insights,
  structured logs, and tracing (X-Ray / OpenTelemetry), with alerting.
- **Security hardening:** OIDC for CI (no static keys), least-privilege IAM,
  Secrets Manager / SSM for secrets, WAF on CloudFront, restrict the ALB to the
  CloudFront managed prefix list, and TLS via ACM + a real domain.
- **Real workloads:** build and push real images to ECR and wire the
  web → SQS → worker flow with an actual application.
- **CI/CD:** a GitHub Actions pipeline — `fmt` / `validate` / `tflint` /
  `checkov` + `plan` on pull requests, gated `apply` on merge, OIDC auth, per
  environment.
- **Resilience & scale:** one NAT per AZ, a `prod` environment and multi-region,
  and step-scaling for faster reaction.

---

## AI assistance disclosure

The **architecture, design trade-offs, and scope were my own**. I designed the
system (see `Infra_Diagram/infra_diagram.jpg`), decided the core/app layer split
for blast-radius isolation, chose what to include and exclude for the demo, and
made the state, networking, and autoscaling decisions. AI tooling was used to
**accelerate the implementation and boilerplate**, not to do the design thinking.

**All of the design thinking is documented in `Design document.pdf` — written
before and independently of any code.** It lays out the requirements and
approach, the target architecture, the key design decisions and their trade-offs
(Fargate vs EKS/EC2, SQS decoupling, S3 + CloudFront frontend, GitHub Actions,
modular monolith, RDS-first / defer-Aurora, CloudWatch-first observability,
single NAT, and more), database scalability, observability and SLOs, CI/CD, a
phased migration roadmap, risks & mitigations, and the security model. This repo
implements a representative slice of that design.

### Tools used
- **Claude Code (Anthropic)** — scaffolded and wrote the Terraform from my
  direction: the layered directory structure, the modules (network, ecs-cluster,
  queue, ecs-service, frontend), the root and per-layer Makefiles, the
  `CLAUDE.md` context file, and this README.
- **Claude** — refined the wording of the design document (`Design document.pdf`).

### Prompts & modifications
Representative prompts I gave during the build (lightly trimmed):
- "Generate a CLAUDE.md to set context — it's a Terraform demo to provision an
  auto-scaling ECS service."
- "I've added the infra diagram; update CLAUDE.md based on it."
- "Set up the Terraform base and initial directory — AWS/Terraform provider
  setup and version pinning."
- "Build the network module; it must be separate from the application logic to
  reduce blast radius — core-infra vs a separate app directory."
- "Build the ecs-cluster module next." / "Build the queue (SQS) module." /
  "Build the frontend (CloudFront + S3) module."
- "Create a Makefile to handle Terraform operations and pull AWS creds from env
  vars for the demo."
- "Make the web autoscaling aggressive so it scales up quickly for the demo."

Substantive decisions and edits I made on top of the generated output:
- Directed the two-layer (core-infra / app) separation and the module boundaries.
- Set the demo scope — excluded the database, kept the worker + SQS path.
- Chose local state with the S3 backend stubbed for later.
- **Reverted an AI-proposed single-root merge** to keep the layered structure.
- Decided the networking approach and tuned/approved the final autoscaling values.
- Reviewed and rewrote README wording and the assumptions / next-steps sections.

### Verification
- Ran `terraform fmt` and `terraform validate` on both layers after each change.

- **Deployed to a real AWS account** and verified autoscaling end-to-end:
  ran a load test against the web service with `hey` and watched ECS scale it
  from 1 to 4 tasks via the Application Auto Scaling activity log.
- Manually reviewed all generated Terraform against the AWS provider docs and the
  project's conventions.

### Exclusions / prohibited
- No unreviewed AI output was submitted — every module and command was read,
  validated, and corrected where needed.
- The architecture diagram is my own; it is not AI-generated.
- I can explain any part of the solution — the layer split and blast-radius
  rationale, the target-tracking autoscaling policy, and the state design —
  without AI assistance.
