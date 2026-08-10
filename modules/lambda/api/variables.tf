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
  description = "The apex domain name"
}

variable "repo_name" {
  type        = string
  description = "The name of the repository"
}

variable "database_name" {
  type        = string
  description = "The name of the RDS database"
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
  description = "Enable SnapStart on published versions. Mutually exclusive with provisioned_concurrent_executions."
  default     = true
}

variable "provisioned_concurrent_executions" {
  type        = number
  description = "Number of provisioned concurrent executions on the live alias. Mutually exclusive with enable_snapstart."
  default     = 0
}

variable "timezone" {
  description = "Timezone for schedules (e.g. Europe/London)"
  type        = string
  default     = "Europe/London"
}

variable "schedule" {
  description = "Cron expression for the scheduled Lambda invoke"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}