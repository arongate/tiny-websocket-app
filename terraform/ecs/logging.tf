### ecs cluster ###

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "cloudwatch logs key"
  deletion_window_in_days = 7
  tags = {
    Name = local.ecs_cluster_name
  }
}

locals {
  ecs_cluster_log_group_name = "/aws/ecs/${local.ecs_cluster_name}"
  ecs_log_group_name         = "/aws/ecs/${local.ecs_cluster_name}/task/${local.ecs_task_def_family}"
}

data "aws_iam_policy_document" "cloudwatch_logs_kms_key_policy" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.ecs_cluster_log_group_name}",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.ecs_log_group_name}"
      ]
    }
  }
}

resource "aws_kms_key_policy" "cloudwatch_logs" {
  key_id = aws_kms_key.cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudwatch_logs_kms_key_policy.json
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = local.ecs_cluster_log_group_name
  retention_in_days = 1
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  tags = {
    Name = "cwlogs-ecs-${local.ecs_cluster_name}"
  }
}

resource "aws_cloudwatch_log_group" "ecs_task" {
  name              = local.ecs_log_group_name
  retention_in_days = var.ecs_cloudwatch_logs_retention_in_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  tags = {
    Name = "cwlogs-ecs-task-${local.ecs_task_def_family}"
  }
}

