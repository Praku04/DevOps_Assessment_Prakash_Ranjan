variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs."
}

variable "container_image" {
  type        = string
  description = "Application image."
}

variable "ecs_cpu" {
  type        = number
  description = "ECS task CPU."
}

variable "ecs_memory" {
  type        = number
  description = "ECS task memory."
}

variable "ecs_desired_count" {
  type        = number
  description = "ECS desired task count."
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class."
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS allocated storage."
}

variable "db_password" {
  type        = string
  description = "Demo database password. Use Secrets Manager for real deployments."
  sensitive   = true
}
