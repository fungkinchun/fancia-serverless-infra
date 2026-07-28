output "api_id" {
  value = aws_apigatewayv2_api.api.id
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "execution_arn" {
  value = aws_apigatewayv2_api.api.execution_arn
}

output "custom_domain" {
  value = local.api_fqdn
}

output "domain_name_target" {
  value = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
}
