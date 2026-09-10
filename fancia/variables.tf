variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
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

variable "public_hosted_zone_id" {
  type        = string
  description = "Public hosted zone ID"
}

variable "private_hosted_zone_id" {
  type        = string
  description = "Private hosted zone ID"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
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
  description = "Repositories"
}

variable "jdbc_database_name" {
  type        = string
  description = "JDBC database name"
  default     = null
}
