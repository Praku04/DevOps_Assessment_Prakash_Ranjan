aws_region                 = "us-east-1"
environment                = "dev"
vpc_cidr                   = "10.10.0.0/16"
availability_zones         = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs        = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs       = ["10.10.101.0/24", "10.10.102.0/24"]
container_image            = "nginx:1.27-alpine"
ecs_cpu                    = 256
ecs_memory                 = 512
ecs_desired_count          = 1
db_instance_class          = "db.t4g.micro"
db_allocated_storage       = 20
db_backup_retention_period = 1
db_deletion_protection     = false
db_multi_az                = false
db_password                = "ChangeMeDevPassword123!"

