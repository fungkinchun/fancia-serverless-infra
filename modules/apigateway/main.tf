locals {
  api_fqdn                   = "api.${var.domain_name}"
  api_gateway_domain_target  = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
  api_gateway_domain_zone_id = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = true
    allow_headers = [
      "authorization",
      "content-type",
      "accept",
      "x-requested-with",
    ]
    allow_methods = ["DELETE", "GET", "OPTIONS", "PATCH", "POST", "PUT"]
    allow_origins = var.cors_allowed_origins
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = var.services

  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "service_root" {
  for_each = var.services

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}

resource "aws_apigatewayv2_route" "service_proxy" {
  for_each = var.services

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /${each.key}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  for_each = var.services

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  qualifier     = "live"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = local.api_fqdn

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_route53_record" "api_public" {
  zone_id = var.public_zone_id
  name    = local.api_fqdn
  type    = "A"

  alias {
    name                   = local.api_gateway_domain_target
    zone_id                = local.api_gateway_domain_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_public_ipv6" {
  zone_id = var.public_zone_id
  name    = local.api_fqdn
  type    = "AAAA"

  alias {
    name                   = local.api_gateway_domain_target
    zone_id                = local.api_gateway_domain_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_private" {
  zone_id = var.private_zone_id
  name    = local.api_fqdn
  type    = "A"

  alias {
    name                   = local.api_gateway_domain_target
    zone_id                = local.api_gateway_domain_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_private_ipv6" {
  zone_id = var.private_zone_id
  name    = local.api_fqdn
  type    = "AAAA"

  alias {
    name                   = local.api_gateway_domain_target
    zone_id                = local.api_gateway_domain_zone_id
    evaluate_target_health = false
  }
}
