output "acm_certificate_arn" {
  description = "Regional ACM certificate ARN for api.{domain_name}"
  value       = module.api_certificate.acm_certificate_arn
}

output "lambda_functions" {
  value = {
    for k, v in module.api_lambda : k => {
      function_name = v.function_name
      function_arn  = v.function_arn
      invoke_arn    = v.invoke_arn
    }
  }
}

output "api_gateway" {
  description = "Shared HTTP API Gateway"
  value = {
    api_id        = module.apigateway.api_id
    api_endpoint  = module.apigateway.api_endpoint
    execution_arn = module.apigateway.execution_arn
    custom_domain = module.apigateway.custom_domain
    domain_target = module.apigateway.domain_name_target
  }
}

output "api_service_urls" {
  description = "Public URL for each Lambda service via path prefix routing"
  value = {
    for repo in var.repositories :
    repo.name => "https://api.${var.domain_name}/${repo.name}"
  }
}
