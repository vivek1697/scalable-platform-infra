# Re-exported for the app layer to consume via terraform_remote_state.
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}

output "availability_zones" {
  description = "Availability Zones the network spans."
  value       = module.network.availability_zones
}

output "nat_public_ip" {
  description = "Fixed egress IP seen by partner systems."
  value       = module.network.nat_public_ip
}
