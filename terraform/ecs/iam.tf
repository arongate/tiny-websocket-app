data "aws_iam_policy_document" "ecs_tasks_execution_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_task_execution_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

locals {
  ecs_task_exec_role_name = coalesce(var.ecs_task_exec_role_name, "test-${local.ecs_svc_name}-task-exec-role")
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = local.ecs_task_exec_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role_trust.json
  inline_policy {
    name   = "custom"
    policy = data.aws_iam_policy_document.ecs_task_execution_role_policy.json
  }
  tags = {
    Name = local.ecs_task_exec_role_name
  }
}


data "aws_iam_policy_document" "ecs_task_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }

  }
}

data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    sid    = "ECSExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.ecs.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.ecs_task.arn}:*"]
  }
}

locals {
  ecs_task_role_name = coalesce(var.ecs_task_role_name, "test-${local.ecs_svc_name}-task-role")
}

resource "aws_iam_role" "ecs_task_role" {
  name               = local.ecs_task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_trust.json
  inline_policy {
    name   = "custom"
    policy = data.aws_iam_policy_document.ecs_task_role_policy.json
  }
  tags = {
    Name = local.ecs_task_role_name
  }
}
