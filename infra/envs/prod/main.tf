locals {
  name = "insurance-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  container_image    = var.container_image
  container_port     = 80
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.ecs_desired_count
}

module "rds" {
  source = "../../modules/rds"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.private_subnet_ids
  ecs_security_group_id   = module.ecs.ecs_security_group_id
  db_name                 = "insurance_db"
  db_username             = "insurance_user"
  db_password             = var.db_password
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
}
