data "aws_region" "current" {}

locals {
  lambda_web_adapter_layer_arn = "arn:aws:lambda:${data.aws_region.current.name}:753240598075:layer:LambdaAdapterLayerX86:27"
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-${var.environment}-${var.repo_name}-api"
  role          = var.lambda_role_arn
  package_type  = "Zip"

  s3_bucket = "${var.project_name}-${var.environment}-backend-artifacts"
  s3_key    = "${var.repo_name}.zip"

  handler       = "run.sh"
  runtime       = "java25"
  memory_size   = 1024
  timeout       = 60
  architectures = ["x86_64"]
  publish       = true
  layers        = [local.lambda_web_adapter_layer_arn]

  dynamic "snap_start" {
    for_each = var.enable_snapstart ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
      PORT                    = "8080"
      JAVA_TOOL_OPTIONS       = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"

      ENV                                = var.environment
      PROJECT_NAME                       = var.project_name
      REPO_NAME                          = var.repo_name
      DOMAIN_NAME                        = var.domain_name
      SPRING_PROFILES_ACTIVE             = var.environment
      AWS_RDS_SECRET_NAME                = var.database_secret_name
      DATABASE_URL                       = "jdbc-secretsmanager:postgresql://${var.database_name}-rds.${var.domain_name}:5432/${var.project_name}"
      AUTH_SERVICE_URL                   = "https://api.${var.domain_name}/auth"
      AUTH_INTERNAL_SERVICE_URL          = "http://internal.${var.domain_name}/auth"
      COMMON_SERVICE_URL                 = "https://api.${var.domain_name}/common"
      COMMON_INTERNAL_SERVICE_URL        = "http://internal.${var.domain_name}/common"
      USER_SERVICE_URL                   = "https://api.${var.domain_name}/user"
      USER_INTERNAL_SERVICE_URL          = "http://internal.${var.domain_name}/user"
      INTERESTGROUP_SERVICE_URL          = "https://api.${var.domain_name}/interestgroup"
      INTERESTGROUP_INTERNAL_SERVICE_URL = "http://internal.${var.domain_name}/interestgroup"
      EVENT_SERVICE_URL                  = "https://api.${var.domain_name}/event"
      EVENT_INTERNAL_SERVICE_URL         = "http://internal.${var.domain_name}/event"
      CDN_URL                            = "https://cdn.${var.domain_name}"
      MAX_POOL_SIZE                      = "5"
      MIN_IDLE                           = "0"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = var.enable_snapstart ? "SnapStart traffic" : "Live traffic"
  function_name    = aws_lambda_function.api.function_name
  function_version = aws_lambda_function.api.version
}

resource "aws_lambda_provisioned_concurrency_config" "api" {
  count = var.provisioned_concurrent_executions > 0 ? 1 : 0

  function_name                     = aws_lambda_function.api.function_name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = aws_lambda_alias.live.name
}

