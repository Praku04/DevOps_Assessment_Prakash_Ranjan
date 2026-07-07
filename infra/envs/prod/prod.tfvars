aws_region                 = "us-east-1"
environment                = "prod"
vpc_cidr                   = "10.20.0.0/16"
availability_zones         = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs        = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs       = ["10.20.101.0/24", "10.20.102.0/24"]
container_image            = "nginx:1.27-alpine"
ecs_cpu                    = 512
ecs_memory                 = 1024
ecs_desired_count          = 2
db_instance_class          = "db.t4g.small"
db_allocated_storage       = 50
db_backup_retention_period = 7
db_deletion_protection     = true
db_multi_az                = true
db_password                = "ChangeMeProdPassword123!"

