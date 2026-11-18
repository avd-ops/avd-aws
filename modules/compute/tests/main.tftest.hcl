mock_provider "aws" {}

run "compute_imdsv2_encrypted_asg_plan" {
  command = plan

  variables {
    environment        = "dev"
    private_subnet_id  = "subnet-00000000000000000"
    security_group_id  = "sg-00000000000000000"
    source_ami_id      = "ami-00000000000000000"
    arc_resource_group = "rg-avd-arc-dev"
    host_pool_name     = "hp-avd-hybrid-dev"
    arc_sp_secret_arn  = "arn:aws:secretsmanager:us-east-1:000000000000:secret:avd-arc-sp-dev-000000"
    session_host_count = 2
  }

  assert {
    condition     = aws_autoscaling_group.session_hosts.name == "asg-avd-hosts-dev"
    error_message = "ASG name should follow asg-avd-hosts-<env>."
  }

  assert {
    condition     = aws_launch_template.session_host.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 (http_tokens = required) must be enforced on session hosts."
  }

  assert {
    condition     = aws_launch_template.session_host.block_device_mappings[0].ebs[0].encrypted == "true" && aws_launch_template.session_host.block_device_mappings[0].ebs[0].volume_type == "gp3"
    error_message = "Root EBS volume must be encrypted gp3."
  }

  assert {
    condition     = length(aws_iam_role_policy.arc_sp_secret) == 1
    error_message = "Scoped Secrets Manager policy must be created when arc_sp_secret_arn is provided."
  }

  assert {
    condition     = aws_iam_role.session_host.name == "role-avd-hosts-dev"
    error_message = "Dedicated least-privilege IAM role must be created for session hosts."
  }
}
