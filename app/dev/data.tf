# Reads the core-infra (dev) outputs. Demo uses local state, so this points at
# the core-infra state file on disk. Switch to the S3 backend config when the
# production-ready remote state is enabled.
data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "${path.module}/../../core-infra/dev/terraform.tfstate"
  }
}

# Web task role: enqueue jobs onto the SQS queue.
data "aws_iam_policy_document" "web_queue_access" {
  statement {
    sid       = "EnqueueJobs"
    actions   = ["sqs:SendMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
    resources = [module.queue.queue_arn]
  }
}

# Worker task role: consume and delete jobs from the SQS queue.
data "aws_iam_policy_document" "worker_queue_access" {
  statement {
    sid = "ConsumeJobs"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [module.queue.queue_arn]
  }
}
