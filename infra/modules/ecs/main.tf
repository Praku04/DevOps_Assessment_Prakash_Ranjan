resource "aws_security_group" "insurance_alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow public HTTP access to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_security_group" "insurance_security_group" {
  name        = "${var.name}-ecs-sg"
  description = "Allow application traffic only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.insurance_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ecs-sg"
  }
}

resource "aws_lb" "insurance_alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.insurance_alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_target_group" "insurance_target_group" {
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.name}-tg"
  }
}

resource "aws_lb_listener" "insurance_listener" {
  load_balancer_arn = aws_lb.insurance_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.insurance_target_group.arn
  }
}

resource "aws_ecs_cluster" "insurance_cluster" {
  name = "${var.name}-cluster"

  tags = {
    Name = "${var.name}-cluster"
  }
}

resource "aws_cloudwatch_log_group" "insurance_log_group" {
  name              = "/ecs/${var.name}"
  retention_in_days = 14

  tags = {
    Name = "${var.name}-log-group"
  }
}

resource "aws_iam_role" "insurance_task_execution_role" {
  name = "${var.name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "insurance_task_execution_policy" {
  role       = aws_iam_role.insurance_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "insurance_task" {
  family                   = "${var.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.insurance_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.insurance_log_group.name
          awslogs-region        = data.aws_region.insurance_current.name
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  tags = {
    Name = "${var.name}-task"
  }
}

resource "aws_ecs_service" "insurance_service" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.insurance_cluster.id
  task_definition = aws_ecs_task_definition.insurance_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.insurance_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.insurance_target_group.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.insurance_listener]

  tags = {
    Name = "${var.name}-service"
  }
}

data "aws_region" "insurance_current" {}
