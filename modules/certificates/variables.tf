variable "project_name" {
  type        = string
  description = "Project name"
}

variable "domain_name" {
  type        = string
  description = "Environment DNS name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "public_zone_id" {
  type        = string
  description = "Public hosted zone ID"
}
