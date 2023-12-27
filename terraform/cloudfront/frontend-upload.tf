locals {
  frontend_static_s3_bucket_name = coalesce(var.frontend_static_s3_bucket_name, "frontend-static-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket" "frontend" {
  bucket = local.frontend_static_s3_bucket_name
  force_destroy = true
  tags = {
    Name = local.frontend_static_s3_bucket_name
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "frontend" {
  depends_on = [aws_s3_bucket_ownership_controls.frontend]

  bucket = aws_s3_bucket.frontend.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "frontend_s3_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.frontend_static_s3_bucket_name}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_s3_bucket_policy.json
}

resource "aws_s3_object" "frontend_content" {
  bucket       = aws_s3_bucket.frontend.id
  key          = basename("${path.module}/../../client/index.html")
  content_type = "text/html"
  source       = "${path.module}/../../client/index.html"

  source_hash = filemd5("${path.module}/../../client/index.html")
}
