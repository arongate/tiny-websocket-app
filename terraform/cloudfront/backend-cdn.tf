locals {
  backend_origin_id     = "backend-origin"
  backend_origin_domain = var.backend_origin_domain_name
  backend_cdn_name      = coalesce(var.backend_cdn_name, "backend-cdn")
}

resource "aws_cloudfront_distribution" "backend" {
  depends_on = [aws_s3_bucket_acl.logs]
  aliases    = [var.backend_cdn_domain_name]
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
    domain_name = local.backend_origin_domain
    origin_id   = local.backend_origin_id
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.backend_origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "origin"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "backend"
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
    acm_certificate_arn            = aws_acm_certificate.backend_cdn.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  tags = {
    Name = local.backend_cdn_name
  }
}

output "backend_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.backend.domain_name
}

resource "aws_route53_record" "backend_domain" {
  zone_id = data.aws_route53_zone.main.id
  name    = var.backend_cdn_domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.backend.domain_name
    zone_id                = aws_cloudfront_distribution.backend.hosted_zone_id
    evaluate_target_health = false
  }
}
