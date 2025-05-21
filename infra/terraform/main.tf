terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "tasktracker_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-tasktracker-vpc"
    Environment = var.environment
  }
}

# Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.tasktracker_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.tasktracker_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-2"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tasktracker_vpc.id

  tags = {
    Name        = "${var.environment}-tasktracker-igw"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tasktracker_vpc.id

  tags = {
    Name        = "${var.environment}-tasktracker-public-route-table"
    Environment = var.environment
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# ECS Cluster
resource "aws_ecs_cluster" "tasktracker_cluster" {
  name = "${var.environment}-tasktracker-cluster"

  tags = {
    Name        = "${var.environment}-tasktracker-cluster"
    Environment = var.environment
  }
}

# ECR Repositories
resource "aws_ecr_repository" "frontend_repo" {
  name = "${var.environment}-tasktracker-frontend"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "backend_repo" {
  name = "${var.environment}-tasktracker-backend"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Security Groups
resource "aws_security_group" "lb_sg" {
  name        = "${var.environment}-tasktracker-lb-sg"
  description = "Load Balancer Security Group"
  vpc_id      = aws_vpc.tasktracker_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-tasktracker-lb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.environment}-tasktracker-ecs-tasks-sg"
  description = "ECS Tasks Security Group"
  vpc_id      = aws_vpc.tasktracker_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-tasktracker-ecs-tasks-sg"
    Environment = var.environment
  }
}

# Load Balancer
resource "aws_lb" "tasktracker_lb" {
  name               = "${var.environment}-tasktracker-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name        = "${var.environment}-tasktracker-lb"
    Environment = var.environment
  }
}

# Target Group for Frontend
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.environment}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.tasktracker_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-frontend-tg"
    Environment = var.environment
  }
}

# Target Group for Backend
resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.environment}-backend-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.tasktracker_vpc.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.environment}-backend-tg"
    Environment = var.environment
  }
}

# Listener for Frontend
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.tasktracker_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# Listener Rule for Backend API
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.frontend_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name              = "/ecs/${var.environment}-tasktracker-frontend"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-tasktracker-frontend-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/ecs/${var.environment}-tasktracker-backend"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-tasktracker-backend-logs"
    Environment = var.environment
  }
}

# ECS Task Definition - Frontend
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.environment}-tasktracker-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-tasktracker-frontend"
      image     = "${aws_ecr_repository.frontend_repo.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      environment = [
        {
          name  = "REACT_APP_API_URL"
          value = "http://${aws_lb.tasktracker_lb.dns_name}/api"
        },
        {
          name  = "REACT_APP_ENV"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.environment}-tasktracker-frontend-task"
    Environment = var.environment
  }
}

# ECS Task Definition - Backend
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.environment}-tasktracker-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-tasktracker-backend"
      image     = "${aws_ecr_repository.backend_repo.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = "5000"
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.environment}-tasktracker-backend-task"
    Environment = var.environment
  }
}

# ECS Service - Frontend
resource "aws_ecs_service" "frontend_service" {
  name            = "${var.environment}-tasktracker-frontend-service"
  cluster         = aws_ecs_cluster.tasktracker_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "${var.environment}-tasktracker-frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.frontend_listener]

  tags = {
    Name        = "${var.environment}-tasktracker-frontend-service"
    Environment = var.environment
  }
}

# ECS Service - Backend
resource "aws_ecs_service" "backend_service" {
  name            = "${var.environment}-tasktracker-backend-service"
  cluster         = aws_ecs_cluster.tasktracker_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "${var.environment}-tasktracker-backend"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.frontend_listener]

  tags = {
    Name        = "${var.environment}-tasktracker-backend-service"
    Environment = var.environment
  }
}

# Outputs
output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.tasktracker_lb.dns_name
}

output "frontend_repository_url" {
  description = "The URL of the frontend repository"
  value       = aws_ecr_repository.frontend_repo.repository_url
}

output "backend_repository_url" {
  description = "The URL of the backend repository"
  value       = aws_ecr_repository.backend_repo.repository_url
}