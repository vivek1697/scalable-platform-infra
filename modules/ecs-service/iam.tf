# Execution role: lets ECS pull the image and write logs.
resource "aws_iam_role" "execution" {
  name               = "${local.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: the identity the running container uses for AWS API calls.
resource "aws_iam_role" "task" {
  name               = "${local.name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# Optional app permissions (e.g. SQS access), supplied by the caller.
# Gated on a static bool, not on the policy value, because the policy JSON can
# reference resources that don't exist at plan time (count must be known).
resource "aws_iam_role_policy" "task" {
  count = var.attach_task_policy ? 1 : 0

  name   = "${local.name}-task-policy"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}
