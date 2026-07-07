output "vpc_id" {
  value = aws_vpc.insurance_vpc.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.insurance_public_subnet_1.id,
    aws_subnet.insurance_public_subnet_2.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.insurance_private_subnet_1.id,
    aws_subnet.insurance_private_subnet_2.id
  ]
}
