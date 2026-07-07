resource "aws_security_group" "insurance_rds_security_group" {
  name        = "${var.name}-rds-sg"
  description = "Allow PostgreSQL only from ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "insurance_db_subnet_group" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

resource "aws_db_instance" "insurance_database" {
  identifier             = "${var.name}-postgres"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.insurance_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.insurance_rds_security_group.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = {
    Name = "${var.name}-postgres"
  }
}
