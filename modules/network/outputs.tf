output "vpc_id" {
  description = "VPC ID hosting the AVD Hybrid session hosts."
  value       = aws_vpc.avd.id
}

output "vpc_name" {
  description = "VPC Name tag."
  value       = aws_vpc.avd.tags["Name"]
}

output "private_subnet_id" {
  description = "Private subnet ID for AVD Hybrid session hosts."
  value       = aws_subnet.hosts.id
}

output "private_subnet_name" {
  description = "Private subnet Name tag."
  value       = aws_subnet.hosts.tags["Name"]
}

output "security_group_id" {
  description = "Security group ID attached to AVD Hybrid session hosts."
  value       = aws_security_group.session_host.id
}
