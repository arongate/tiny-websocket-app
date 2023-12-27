resource "aws_acm_certificate" "backend_cdn" {
  provider          = aws.us-east-1
  domain_name       = var.backend_cdn_domain_name
  validation_method = "DNS"

  tags = {
    Name = var.backend_cdn_domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "backend_cdn_validation" {
  for_each = {
    for dvo in aws_acm_certificate.backend_cdn.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "backend_cdn" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.backend_cdn.arn
  validation_record_fqdns = [for record in aws_route53_record.backend_cdn_validation : record.fqdn]
}
