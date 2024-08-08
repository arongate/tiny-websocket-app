variable "aws_region" {
  type        = string
  description = "The deployment aws region."
  default     = "eu-central-1"
}

variable "ecr_repository_name" {
  type        = string
  description = "The ECR repository name. Generated if not provided."
  default     = null
}

variable "lb_sg_name" {
  type        = string
  description = "The load balancer security group name. Generated if not provided."
  default     = null
}

variable "lb_logs_bucket_name" {
  type        = string
  description = "The load balancer logs bucket name. Generated if not provided."
  default     = null
}

variable "lb_name" {
  type        = string
  description = "The load balancer name. Generated if not provided."
  default     = null
}

variable "target_group_name" {
  type        = string
  description = "The target group name. Generated if not provided."
  default     = null
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ecs cluster to create. Generated if not provided."
  default     = null
}

### iam ###

variable "ecs_task_exec_role_name" {
  type        = string
  description = "The name of the ecs task execution role. Generated if not provided."
  default     = null
}

variable "ecs_task_role_name" {
  type        = string
  description = "The name of the ecs task role. Generated if not provided."
  default     = null
}

### security ###

variable "ecs_task_sg_name" {
  type        = string
  description = "The ecs task security group name."
  default     = null
}

variable "ecs_svc_name" {
  type        = string
  description = "The ecs service name. Generated if not provided."
  default     = null
}

# network configuration
variable "vpc_cidr_block" {
  type        = string
  description = "The vpc cidr block."
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "The VPC name."
}

variable "vpce_sg_name" {
  type        = string
  description = "VPC Endpoint security group name. Generated if not provided."
  default     = null
}

variable "existing_route53_zone_name" {
  type        = string
  description = "The name of the existing public route53 zone to use."
}

variable "lb_certificate_fqdn" {
  type        = string
  description = "The loadblancer public certificate dns identifier (common name)."
}

# app configuration
variable "app_port" {
  type        = number
  description = "The application port."
  default     = 8080
}

variable "alb_account_id" {
  type        = string
  description = <<EOT
The AWS account ID of the ALB service account.
see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
EOT
}

variable "ecs_cloudwatch_logs_retention_in_days" {
  type        = number
  description = "The number of days to retain the ecs cloudwatch logs."
  default     = 3
}
