variable "aws_region" {
  type        = string
  description = "The deployment aws region."
  default     = "eu-central-1"
}

variable "cloudfront_logs_bucket_name" {
  type        = string
  description = "The cloudfront logs s3 bucket name. Generated if not provided."
  default     = null
}

# frontend variables
variable "frontend_cdn_domain_name" {
  type        = string
  description = "The frontend distribution domain name. used as aliases."
}

variable "frontend_cdn_name" {
  type        = string
  description = "The name of the frontend cdn. Generated if not provided."
  default     = null
}

variable "frontend_origin_access_control_name" {
  type        = string
  description = "The frontend origin access control policy name. Generated if not provided."
  default     = null
}

variable "frontend_static_s3_bucket_name" {
  type        = string
  description = "The static frontend s3 bucket name. Generated if not provided."
  default     = null
}

# backend variables

variable "backend_cdn_domain_name" {
  type        = string
  description = "The backend distribution domain name."
}

variable "backend_origin_domain_name" {
  type        = string
  description = "The server origin domain name."
}

variable "backend_cdn_name" {
  type        = string
  description = "The backend cdn name. Generated if not provided."
  default     = null
}

variable "existing_route53_zone_name" {
  type        = string
  description = "The existing route53 public zone used to create record."
}
