output "myvpc_id" {
  value       = aws_vpc.myvpc.id
  description = "The ID of VPC"
}

output "mysubnet_ids" {
  value       = aws_subnet.public_subnets.*.id
  description = "The ID of VPC"
}
