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
  description = "The apex domain name"
}

variable "public_hosted_zone_id" {
  type        = string
  description = "Route 53 public hosted zone ID"
}

variable "private_hosted_zone_id" {
  type        = string
  description = "Route 53 private hosted zone ID for VPC DNS"
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
  }))
  description = "List of repositories"
}
