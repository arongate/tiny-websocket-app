terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform = "true"
      Env       = "test"
    }
  }
}

resource "aws_kms_key" "ecs" {
  description             = "ecs key"
  deletion_window_in_days = 7
  tags = {
    Name = local.ecs_cluster_name
  }
}

locals {
  ecs_cluster_name = coalesce(var.ecs_cluster_name, "test")
}

resource "aws_kms_alias" "ecs" {
  name          = "alias/ecs-${local.ecs_cluster_name}"
  target_key_id = aws_kms_key.ecs.key_id
}

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "cloudwatch logs key"
  deletion_window_in_days = 7
  tags = {
    Name = local.ecs_cluster_name
  }
}

locals {
  ecs_log_group_name = "/aws/ecs/${local.ecs_cluster_name}"
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
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.ecs_log_group_name}"]
    }
  }
}

resource "aws_kms_key_policy" "cloudwatch_logs" {
  key_id = aws_kms_key.cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudwatch_logs_kms_key_policy.json
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = local.ecs_log_group_name
  retention_in_days = 1
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  tags = {
    Name = "cwlogs-ecs-${local.ecs_cluster_name}"
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }
  tags = {
    Name = local.ecs_cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_task_custom_policy" {
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
  ecs_task_exec_role_name = coalesce(var.ecs_task_exec_role_name, "${local.ecs_cluster_name}-task-exec-role")
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = local.ecs_task_exec_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
  inline_policy {
    name   = "custom"
    policy = data.aws_iam_policy_document.ecs_task_custom_policy.json
  }
  tags = {
    Name = local.ecs_task_exec_role_name
  }
}

locals {
  ecs_task_def_family = "test"
  container_name      = "app"
}

resource "aws_ecs_task_definition" "app" {
  family                   = local.ecs_task_def_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name               = local.container_name
      image              = aws_ecr_repository.app.repository_url
      cpu                = 1024
      memory             = 2048
      essential          = true
      initProcessEnabled = true
      environment = [
        { "name" = "PORT", "value" = tostring(var.app_port) }
      ]
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = 8080
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  tags = {
    Name = local.ecs_task_def_family
  }
}

locals {
  ecs_task_sg_name = coalesce(var.ecs_task_sg_name, "app-ecs-task")
}

resource "aws_security_group" "ecs_task" {
  name        = local.ecs_task_sg_name
  description = "ecs tasks."
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = local.ecs_task_sg_name
  }
}

resource "aws_security_group_rule" "ecs_task_from_lb" {
  security_group_id        = aws_security_group.ecs_task.id
  description              = "All from LB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "ecs_task_to_all_ipv4" {
  security_group_id = aws_security_group.ecs_task.id
  description       = "All to All"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  ecs_svc_name = coalesce(var.ecs_svc_name, "app")
}

resource "aws_ecs_service" "app" {
  name            = local.ecs_svc_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.container_name
    container_port   = var.app_port
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_task.id]
  }
  tags = {
    Name = local.ecs_svc_name
  }
}

