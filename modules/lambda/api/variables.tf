variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Lambda"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda"
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository name for the API container image"
}

variable "image_tag" {
  type        = string
  description = "Container image tag to deploy"
  default     = "latest"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the project"
}

variable "internal_dns_domain" {
  type        = string
  description = "The domain name for internal DNS"
  default     = null
}

variable "rds_dns_domain" {
  type        = string
  description = "The domain name for RDS DNS"
  default     = null
}

variable "repo_name" {
  type        = string
  description = "The name of the repository"
}

variable "database_name" {
  type        = string
  description = "The name of the RDS database"
}

variable "jdbc_database_name" {
  type        = string
  description = "The JDBC database name"
  default     = null
}

variable "database_secret_name" {
  type        = string
  description = "The name of the Secrets Manager secret containing RDS credentials"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN of the IAM role that the Lambda function will assume"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach to the Lambda function"
}

variable "enable_snapstart" {
  type        = bool
  description = "Enable SnapStart on published versions"
  default     = true
}

variable "provisioned_concurrent_executions" {
  type        = number
  description = "Number of provisioned concurrent executions"
  default     = 0
}

variable "timezone" {
  type        = string
  description = "Timezone for schedules"
  default     = "Europe/London"
}

variable "schedule" {
  type        = string
  description = "Cron expression for the scheduled Lambda invoke"
  default     = null
}

variable "is_cron" {
  type        = bool
  description = "Whether this is a cron Lambda"
  default     = false
}

variable "handler" {
  type        = string
  description = "The Lambda handler"
  default     = null
}
