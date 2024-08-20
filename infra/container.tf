# just use current aws region when region is required
data "aws_region" "current" {}

# Get account id for policy creation
data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "app_api_key" {
  name  = "/app/${var.api_key}"
  value = var.api_key
  type  = "String"
}


# Role/Policy for ECS execution policy that gives the required access
resource "aws_iam_role" "ecs_role" {
  name = "app_ecs_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name        = "app_ecs_policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameters",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:GetAuthorizationToken"
          ],
          "Resource" : [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/app/*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          ]
        },
        {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
      ]
    })
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "app_ecs_task_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "app_ecs_task_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          ]
        }
      ]
    })
  }
}


locals {
  app_endpoint = aws_lb.app_nlb.dns_name
  container_definition = [
    {
      name = "balance-app-container"
      memory = 100
      image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/balance-app:${var.app_version}"
      essential    = true
      portMappings = [
        {
          "containerPort":5000,
          "hostPort":5000
        }    
      ]
      secrets = [
        {
          name      = "INFURA_API_KEY"
          valueFrom = aws_ssm_parameter.app_api_key.arn

        }
      ]
      environment = [
        {
          "name"  = "LOG_LEVEL"
          "value" = "info"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-create-group"  = "true",
          "awslogs-group"         = "/ecs/balance-app/",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "balance-app-logs"
        }
      }
    },
  ]
}

