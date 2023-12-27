locals {
  frontend_origin_access_control_name = coalesce(var.frontend_origin_access_control_name, "frontend-s3-origin")
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = local.frontend_origin_access_control_name
  description                       = "Frontend origin access control Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  frontend_origin_id = "frontend-origin"
  frontend_cdn_name  = coalesce(var.frontend_cdn_name, "frontend-cdn")
}

resource "aws_cloudfront_distribution" "frontend" {
  depends_on = [aws_s3_bucket_acl.logs]
  aliases    = [var.frontend_cdn_domain_name]

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    origin_id                = local.frontend_origin_id
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.frontend_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "origin"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "frontend"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.frontend_cdn.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  tags = {
    Name = local.frontend_cdn_name
  }
}

output "frontend_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

resource "aws_route53_record" "frontend_domain" {
  zone_id = data.aws_route53_zone.main.id
  name    = var.frontend_cdn_domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
