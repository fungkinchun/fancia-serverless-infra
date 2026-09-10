variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository name"
}

variable "image_tag" {
  type        = string
  description = "Image tag"
  default     = "latest"
}

variable "domain_name" {
  type        = string
  description = "Environment DNS name"
}

variable "internal_dns_domain" {
  type        = string
  description = "Internal DNS domain"
  default     = null
}

variable "rds_dns_domain" {
  type        = string
  description = "RDS DNS domain"
  default     = null
}

variable "repo_name" {
  type        = string
  description = "Repository name"
}

variable "database_name" {
  type        = string
  description = "RDS database name"
}

variable "jdbc_database_name" {
  type        = string
  description = "JDBC database name"
  default     = null
}

variable "database_secret_name" {
  type        = string
  description = "RDS secret name"
}

variable "lambda_role_arn" {
  type        = string
  description = "Lambda role ARN"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
}

variable "enable_snapstart" {
  type        = bool
  description = "Enable SnapStart"
  default     = true
}

variable "provisioned_concurrent_executions" {
  type        = number
  description = "Provisioned concurrency"
  default     = 0
}

variable "timezone" {
  type        = string
  description = "Schedule timezone"
  default     = "Europe/London"
}

variable "schedule" {
  type        = string
  description = "Cron schedule"
  default     = null
}

variable "is_cron" {
  type        = bool
  description = "Cron Lambda"
  default     = false
}

variable "handler" {
  type        = string
  description = "Lambda handler"
  default     = null
}
