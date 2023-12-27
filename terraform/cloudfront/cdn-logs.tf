
locals {
  cloudfront_logs_bucket_name = coalesce(var.cloudfront_logs_bucket_name, "cloudfront-logs-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "logs" {
  bucket        = local.cloudfront_logs_bucket_name
  force_destroy = true
  tags = {
    Name = local.cloudfront_logs_bucket_name
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}
