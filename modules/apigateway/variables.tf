variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the project"
}

variable "public_zone_id" {
  type        = string
  description = "Route 53 public hosted zone ID"
}

variable "private_zone_id" {
  type        = string
  description = "Route 53 private hosted zone ID"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Browser origins allowed by API Gateway CORS"
}

variable "services" {
  type = map(object({
    lambda_invoke_arn    = string
    lambda_function_name = string
  }))
  description = "Map of service path prefixes to Lambda targets"
}
