locals {
  registry_host_name = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

resource "null_resource" "ecr_registry_auth" {

  provisioner "local-exec" {
    command = <<EOF
	aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${local.registry_host_name}
  EOF
  }

  # triggers = {
  #   "run_at" = timestamp()
  # }

  depends_on = [
    aws_ecr_repository.app,
  ]
}

provider "docker" {
  registry_auth {
    address = "https://${local.registry_host_name}"
  }
}

locals {
  ecr_repository_name = coalesce(var.ecr_repository_name, "app")
}

resource "aws_ecr_repository" "app" {
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "docker_image" "app" {
  name = "${aws_ecr_repository.app.repository_url}:latest"
  build {
    auth_config {
      host_name = local.registry_host_name
    }
    context = "${path.module}/../../server"
    tag     = ["${aws_ecr_repository.app.repository_url}:latest"]
    build_arg = {
      "--file" : "${path.module}/../../server/Dockerfile"
    }
    network_mode    = "host" # required to force use host machine proxy
    suppress_output = false
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../server/*") : filesha1(f)]))
  }
}

resource "docker_registry_image" "app" {
  name          = docker_image.app.name
  keep_remotely = true
}

data "aws_iam_policy_document" "app_ecr_repository_policy" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = data.aws_iam_policy_document.app_ecr_repository_policy.json
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

resource "aws_ecr_registry_policy" "this" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "repl",
        Effect = "Allow",
        Principal = {
          "AWS" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "ecr:ReplicateImage"
        ],
        Resource = [
          "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
        ]
      }
    ]
  })
}
