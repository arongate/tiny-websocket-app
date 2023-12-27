data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = var.existing_route53_zone_name
  private_zone = false
}
