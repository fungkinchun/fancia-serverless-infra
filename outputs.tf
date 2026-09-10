output "prod" {
  description = "Prod outputs"
  value = {
    domain_name            = module.prod.domain_name
    jdbc_database_name     = module.prod.jdbc_database_name
    aws_account_id         = data.aws_caller_identity.current.account_id
    vpc_id                 = module.prod.vpc_id
    acm_certificate_arn    = module.prod.acm_certificate_arn
    private_hosted_zone_id = module.prod.private_hosted_zone_id
    public_hosted_zone_id  = module.prod.public_hosted_zone_id
    subnet_ids             = module.prod.subnet_ids
    lambda_functions       = module.prod.lambda_functions
    api_gateway            = module.prod.api_gateway
    api_service_urls       = module.prod.api_service_urls
  }
  sensitive = true
}

output "dev" {
  description = "Dev outputs"
  value = {
    domain_name            = module.dev.domain_name
    jdbc_database_name     = module.dev.jdbc_database_name
    aws_account_id         = data.aws_caller_identity.current.account_id
    vpc_id                 = module.dev.vpc_id
    acm_certificate_arn    = module.dev.acm_certificate_arn
    private_hosted_zone_id = module.dev.private_hosted_zone_id
    public_hosted_zone_id  = module.dev.public_hosted_zone_id
    subnet_ids             = module.dev.subnet_ids
    lambda_functions       = module.dev.lambda_functions
    api_gateway            = module.dev.api_gateway
    api_service_urls       = module.dev.api_service_urls
  }
  sensitive = true
}
