module "prod" {
  source = "./fancia"

  project_name           = var.prod.project_name
  environment            = "prod"
  aws_region             = var.prod.aws_region
  domain_name            = var.prod.domain_name
  vpc_id                 = var.prod.vpc_id
  subnet_ids             = var.prod.subnet_ids
  public_hosted_zone_id  = var.prod.public_hosted_zone_id
  private_hosted_zone_id = var.prod.private_hosted_zone_id
  repositories           = var.prod.repositories
  jdbc_database_name     = try(var.prod.jdbc_database_name, null)
  internal_dns_domain    = try(var.prod.internal_dns_domain, null)
  rds_dns_domain         = try(var.prod.rds_dns_domain, null)
}

module "dev" {
  source = "./fancia"

  project_name           = var.dev.project_name
  environment            = "dev"
  aws_region             = var.dev.aws_region
  domain_name            = var.dev.domain_name
  vpc_id                 = var.dev.vpc_id
  subnet_ids             = var.dev.subnet_ids
  public_hosted_zone_id  = var.dev.public_hosted_zone_id
  private_hosted_zone_id = var.dev.private_hosted_zone_id
  repositories           = var.dev.repositories
  jdbc_database_name     = try(var.dev.jdbc_database_name, null)
  internal_dns_domain    = try(var.dev.internal_dns_domain, null)
  rds_dns_domain         = coalesce(try(var.dev.rds_dns_domain, null), var.prod.domain_name)
}

data "aws_caller_identity" "current" {}
