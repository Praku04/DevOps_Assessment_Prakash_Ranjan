output "security_group_id" {
  value = aws_security_group.insurance_rds_security_group.id
}

output "endpoint" {
  value = aws_db_instance.insurance_database.endpoint
}

output "db_name" {
  value = aws_db_instance.insurance_database.db_name
}
