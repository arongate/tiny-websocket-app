data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  size           = 2
  vpc_cidr_block = var.vpc_cidr_block
  azs            = slice(data.aws_availability_zones.available.names, 0, local.size)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = local.vpc_cidr_block

  azs             = local.azs
  private_subnets = [for i in range(local.size) : cidrsubnet(local.vpc_cidr_block, 8, i)]
  public_subnets  = [for i in range(local.size) : cidrsubnet(local.vpc_cidr_block, 8, i + 100)]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# aws private link

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
}

data "aws_prefix_list" "private_s3" {
  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
  name           = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "private_subnets_a_to_s3" {
  route_table_id  = module.vpc.private_route_table_ids[0]
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "private_subnets_b_to_s3" {
  route_table_id  = module.vpc.private_route_table_ids[1]
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

locals {
  vpce_sg_name = coalesce(var.vpce_sg_name, "${var.vpc_name}-vpce-sg")
}

resource "aws_security_group" "vpce" {
  name   = local.vpce_sg_name
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = local.vpce_sg_name
  }
}

resource "aws_security_group_rule" "vpce_ingress_from_ecs_tasks" {
  security_group_id        = aws_security_group.vpce.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ecs_task.id
}

resource "aws_security_group_rule" "vpce_egress_to_all_ipv4" {
  security_group_id = aws_security_group.vpce.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_iam_policy_document" "ecr_vpc_endpoint_policy" {
  statement {
    sid    = "AllowAll"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["*"]
    resources = ["*"]
  }
  statement {
    sid    = "PreventDelete"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["ecr:DeleteRepository"]
    resources = [aws_ecr_repository.app.repository_url]
  }
  statement {
    sid    = "AllowPull"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_execution_role.arn]
    }
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  policy              = data.aws_iam_policy_document.ecr_vpc_endpoint_policy.json
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
#   private_dns_enabled = true
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpce.id]
#   vpc_endpoint_type   = "Interface"
#   dns_options {
#     dns_record_ip_type = "ipv4"
#   }
# }

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
#   private_dns_enabled = true
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.vpce.id]
#   vpc_endpoint_type   = "Interface"
#   dns_options {
#     dns_record_ip_type = "ipv4"
#   }
# }

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}

resource "aws_vpc_endpoint" "kms_fips" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms-fips"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
}
