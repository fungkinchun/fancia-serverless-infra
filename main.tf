provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform   = "true"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.project_name}-${var.environment}-api-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "api" {
  name = "api-lambda-policy"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowGlobalList"
        Effect   = "Allow"
        Action   = ["secretsmanager:ListSecrets"]
        Resource = "*"
      },
      {
        Sid    = "AllowScopedRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "AllowAppBucketObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-bucket/*"
      },
      {
        Sid    = "AllowAppBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-bucket"
      }
    ]
  })
}

resource "aws_security_group" "api" {
  name        = "${var.project_name}-${var.environment}-api-lambda-sg"
  description = "Security group for API Lambdas and internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "internal" {
  name               = "${var.environment}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.api.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

locals {
  http_repositories = { for repo in var.repositories : repo.name => repo if !repo.is_cron }
}

resource "aws_lb_target_group" "internal" {
  for_each = local.http_repositories

  name        = "${var.environment}-${each.key}-int-tg"
  target_type = "lambda"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 35
    timeout             = 30
    path                = "/${each.key}/actuator/health"
    matcher             = "200-399"
  }
  depends_on = [module.api_lambda]
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "internal" {
  for_each = local.http_repositories

  listener_arn = aws_lb_listener.internal.arn
  priority     = 100 + index(sort(keys(local.http_repositories)), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}", "/${each.key}/*"]
    }
  }
}

resource "aws_route53_record" "internal" {
  zone_id = var.private_hosted_zone_id
  name    = "internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

module "api_certificate" {
  source = "./modules/certificates"

  project_name   = var.project_name
  domain_name    = var.domain_name
  environment    = var.environment
  region         = var.aws_region
  public_zone_id = var.public_hosted_zone_id
}

module "api_lambda" {
  source = "./modules/lambda/api"
  for_each = {
    for repo in var.repositories : repo.name => repo
  }
  project_name                      = var.project_name
  environment                       = var.environment
  region                            = var.aws_region
  vpc_id                            = var.vpc_id
  subnet_ids                        = var.subnet_ids
  ecr_repository_name               = "${var.project_name}-backend-${each.value.name}"
  domain_name                       = var.domain_name
  repo_name                         = each.value.name
  database_name                     = each.value.database_name
  database_secret_name              = each.value.database_secret_name
  lambda_role_arn                   = aws_iam_role.api.arn
  schedule                          = each.value.is_cron ? coalesce(each.value.schedule, "cron(0 0 * * ? *)") : null
  is_cron                           = each.value.is_cron
  handler                           = try(each.value.handler, null)
  security_group_ids                = [aws_security_group.api.id]
  enable_snapstart                  = each.value.is_cron ? false : (each.value.name == "auth" ? false : true)
  provisioned_concurrent_executions = each.value.name == "auth" ? 1 : 0
}

resource "aws_lambda_permission" "internal" {
  for_each = local.http_repositories

  statement_id  = "AllowInternalALBInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.api_lambda[each.key].function_name
  qualifier     = "live"
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.internal[each.key].arn
}

resource "aws_lb_target_group_attachment" "internal" {
  for_each = local.http_repositories

  target_group_arn = aws_lb_target_group.internal[each.key].arn
  target_id        = "${module.api_lambda[each.key].function_arn}:live"
  depends_on       = [aws_lambda_permission.internal, aws_lb_listener.internal]
}

module "apigateway" {
  source = "./modules/apigateway"

  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.domain_name
  public_zone_id      = var.public_hosted_zone_id
  private_zone_id     = var.private_hosted_zone_id
  acm_certificate_arn = module.api_certificate.acm_certificate_arn
  cors_allowed_origins = [
    "https://${var.domain_name}",
    "https://www.${var.domain_name}",
    "http://localhost:3000"
  ]

  services = {
    for name, repo in local.http_repositories : name => {
      lambda_invoke_arn    = module.api_lambda[name].invoke_arn
      lambda_function_name = module.api_lambda[name].function_name
    }
  }
}
