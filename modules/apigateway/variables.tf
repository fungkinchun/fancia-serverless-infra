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
  description = "Apex domain name (custom domain will be api.{domain_name})"
}

variable "public_zone_id" {
  type        = string
  description = "Route 53 public hosted zone ID for the api.{domain_name} alias record"
}

variable "private_zone_id" {
  type        = string
  description = "Route 53 private hosted zone ID for in-VPC resolution of api.{domain_name}"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN in the same region as the API Gateway (REGIONAL endpoint)"
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
  description = "Map of service path prefixes to Lambda integration targets (key = URL prefix, e.g. auth)"
}
