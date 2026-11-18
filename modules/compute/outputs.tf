output "autoscaling_group_name" {
  description = "Auto Scaling Group name managing the AVD Hybrid session hosts."
  value       = aws_autoscaling_group.session_hosts.name
}

output "launch_template_id" {
  description = "EC2 Launch Template ID for AVD Hybrid session hosts."
  value       = aws_launch_template.session_host.id
}

output "iam_role_name" {
  description = "Least-privilege IAM role name attached to AVD Hybrid session hosts."
  value       = aws_iam_role.session_host.name
}
