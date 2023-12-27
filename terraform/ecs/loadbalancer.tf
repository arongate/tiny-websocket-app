locals {
  lb_sg_name = coalesce(var.lb_sg_name, "lb-sg")
}

resource "aws_security_group" "lb" {
  name   = local.lb_sg_name
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = local.lb_sg_name
  }
}

locals {
  lb_sg_https_ingress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_from_internet_ipv4" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = local.lb_sg_https_ingress_cidr_blocks
  #   ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "egress_to_internet_ipv4" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "egress_to_internet_ipv6" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.lb.id
}

locals {
  lb_logs_bucket_name = coalesce(var.lb_logs_bucket_name, "lb-logs-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = local.lb_logs_bucket_name
  tags = {
    Name = local.lb_logs_bucket_name
  }
}

resource "aws_s3_bucket_ownership_controls" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lb_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.lb_logs]

  bucket = aws_s3_bucket.lb_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "lb_logs_resource_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::054676820928:root"] # see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
    }
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${local.lb_logs_bucket_name}/access/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "arn:aws:s3:::${local.lb_logs_bucket_name}/connection/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = data.aws_iam_policy_document.lb_logs_resource_policy.json
}

locals {
  lb_name = coalesce(var.lb_name, "lb")
}

resource "aws_lb" "this" {
  depends_on         = [aws_s3_bucket_acl.lb_logs]
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "access"
    enabled = true
  }

  connection_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "connection"
    enabled = true
  }

  tags = {
    Name = local.lb_name
  }
}

locals {
  tg_name = coalesce(var.target_group_name, "app-tg")
}

resource "aws_lb_target_group" "app" {
  name        = local.tg_name
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    enabled             = true
    interval            = 5
    timeout             = 3
    healthy_threshold   = 2
    path                = "/health"
    protocol            = "HTTP"
    unhealthy_threshold = 5
  }
  tags = {
    Name = local.tg_name
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_route53_record" "lb" {
  zone_id = data.aws_route53_zone.main.id
  name    = var.lb_certificate_fqdn
  type    = "A"
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}
