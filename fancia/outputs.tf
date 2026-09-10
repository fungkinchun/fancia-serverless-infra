output "domain_name" {
  description = "Environment DNS name"
  value       = local.dns_name
}

output "jdbc_database_name" {
  description = "JDBC database name"
  value       = local.jdbc_database_name
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.api_certificate.acm_certificate_arn
}

output "lambda_functions" {
  description = "Lambda functions"
  value = {
    for k, v in module.api_lambda : k => {
      function_name = v.function_name
      function_arn  = v.function_arn
      invoke_arn    = v.invoke_arn
    }
  }
}

output "api_gateway" {
  description = "API Gateway"
  value = {
    api_id        = module.apigateway.api_id
    api_endpoint  = module.apigateway.api_endpoint
    execution_arn = module.apigateway.execution_arn
    custom_domain = module.apigateway.custom_domain
    domain_target = module.apigateway.domain_name_target
  }
}

output "api_service_urls" {
  description = "Public service URLs"
  value = {
    for repo in var.repositories :
    repo.name => "https://api.${local.dns_name}/${repo.name}"
  }
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = var.subnet_ids
}

output "public_hosted_zone_id" {
  description = "Public hosted zone ID"
  value       = var.public_hosted_zone_id
}

output "private_hosted_zone_id" {
  description = "Private hosted zone ID"
  value       = var.private_hosted_zone_id
}
