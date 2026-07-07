variable "name" {
  description = "Name prefix for ECS resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "container_image" {
  description = "Container image for the service."
  type        = string
}

variable "container_port" {
  description = "Container port exposed by the task."
  type        = number
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
}

variable "memory" {
  description = "Fargate task memory."
  type        = number
}

variable "desired_count" {
  description = "Number of ECS tasks."
  type        = number
}

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
