# Dead-letter queue: holds messages that fail processing max_receive_count times.
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name}-${var.queue_name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = true
}

# Main jobs queue: web enqueues, worker polls/consumes. Scales worker on depth.
resource "aws_sqs_queue" "main" {
  name                       = "${local.name}-${var.queue_name}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}
