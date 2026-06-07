output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ALB, NAT Gateway)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (ECS Fargate tasks)."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability Zones the subnets span."
  value       = local.azs
}

output "nat_public_ip" {
  description = "Fixed egress IP (NAT Gateway EIP) seen by partner systems."
  value       = aws_eip.nat.public_ip
}
