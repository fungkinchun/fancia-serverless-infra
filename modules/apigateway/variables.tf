variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "domain_name" {
  type        = string
  description = "Environment DNS name"
}

variable "public_zone_id" {
  type        = string
  description = "Public hosted zone ID"
}

variable "private_zone_id" {
  type        = string
  description = "Private hosted zone ID"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "CORS allowed origins"
}

variable "services" {
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
  }))
  description = "Service Lambda targets"
}
