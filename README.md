# scalable-platform-infra

Terraform IaC for an auto-scaling **ECS Fargate** platform on AWS. It is split
into two layers — **core** (network + ECS cluster) and **app** (queue, web and
worker services, frontend) — each with its own state. See
`Infra_Diagram/infra_diagram.jpg` for the architecture.

This is a demo. It runs on **local state** (no S3 backend) so it is easy to spin
up and tear down.

---

## What you need first

You need an **AWS account** and credentials, plus a few command-line tools.

| Tool | Why | Install |
|------|-----|---------|
| Terraform (>= 1.9) | Provision the infrastructure | `brew install hashicorp/tap/terraform` |
| AWS CLI v2 | Deploy + run the demo commands | official installer (see below) |
| hey | Generate HTTP load for the scaling demo | `brew install hey` |
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
app**.

---

## Deploy

You can use `make` (recommended) or plain `terraform`. Each layer has its own
Makefile, so run the commands from inside that layer's folder.

```bash
# 1. Core layer first
cd core-infra/dev
make init
make plan
make apply

# 2. App layer second
cd ../../app/dev
make init
make plan
make apply
```

When the app layer finishes, see the important URLs:

```bash
make output      # web_alb_dns_name, frontend_url, queue_url, ...
```

To tear everything down, destroy in the **reverse** order (app first, then core):

```bash
cd app/dev        && make destroy
cd ../../core-infra/dev && make destroy
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
