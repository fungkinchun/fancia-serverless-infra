variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
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

variable "public_hosted_zone_id" {
  type        = string
  description = "Route 53 public hosted zone ID"
}

variable "private_hosted_zone_id" {
  type        = string
  description = "Route 53 private hosted zone ID"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Lambda"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda"
}

variable "repositories" {
  type = list(object({
    name                 = string
    database_name        = string
    database_secret_name = string
    jdbc_database_name   = optional(string)
    is_cron              = bool
    schedule             = optional(string)
    port                 = optional(number)
    image_version        = optional(string)
    handler              = optional(string)
  }))
  description = "List of repositories"
}

variable "jdbc_database_name" {
  type        = string
  description = "The JDBC database name"
  default     = null
}
