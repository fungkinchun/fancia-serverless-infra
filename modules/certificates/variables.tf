variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the certificate (e.g., example.com)"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "region" {
  type        = string
  description = "AWS region for the EKS cluster"
}

variable "public_zone_id" {
  type        = string
  description = "Route 53 public hosted zone ID for ACM DNS validation"
}