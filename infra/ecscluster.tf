
resource "aws_ecs_cluster" "app_cluster" {
  name  = "app_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "app_capacity_provider" {

  cluster_name       = aws_ecs_cluster.app_cluster.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow inbound access to app ports"

  vpc_id = var.vpc_id
  
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app_nlb" {
  name                             = "app-nlb"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = var.subnets
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 5000
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_ecs_task_definition" "app_task_definition" {
  family                   = "app-task"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  container_definitions    = jsonencode(local.container_definition)
}

resource "aws_ecs_service" "app_service" {

  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.arn
  task_definition = aws_ecs_task_definition.app_task_definition.arn
  desired_count   = var.ecs_service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "balance-app-container"
    container_port   = aws_lb_target_group.app_tg.port
  }
}