variable "prod" {
  type = object({
    project_name           = string
    aws_region             = string
    domain_name            = string
    vpc_id                 = string
    subnet_ids             = list(string)
    public_hosted_zone_id  = string
    private_hosted_zone_id = string
    jdbc_database_name     = optional(string)
    internal_dns_domain    = optional(string)
    rds_dns_domain         = optional(string)
    repositories = list(object({
      name                 = string
      database_name        = string
      database_secret_name = string
      jdbc_database_name   = optional(string)
      is_cron              = bool
      schedule             = optional(string)
      port                 = optional(number)
      image_version        = optional(string)
      handler              = optional(string)
    }))
  })
  description = "Prod environment values"
}

variable "dev" {
  type = object({
    project_name           = string
    aws_region             = string
    domain_name            = string
    vpc_id                 = string
    subnet_ids             = list(string)
    public_hosted_zone_id  = string
    private_hosted_zone_id = string
    jdbc_database_name     = optional(string)
    internal_dns_domain    = optional(string)
    rds_dns_domain         = optional(string)
    repositories = list(object({
      name                 = string
      database_name        = string
      database_secret_name = string
      jdbc_database_name   = optional(string)
      is_cron              = bool
      schedule             = optional(string)
      port                 = optional(number)
      image_version        = optional(string)
      handler              = optional(string)
    }))
  })
  description = "Dev environment values"
}
