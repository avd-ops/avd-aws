mock_provider "aws" {}

run "hybrid_root_outputs_plan" {
  command = plan

  variables {
    region             = "us-east-1"
    availability_zone  = "us-east-1a"
    environment        = "dev"
    profile            = "lab"
    source_ami_id      = "ami-00000000000000000"
    session_host_count = 1
    arc_resource_group = "rg-avd-arc-dev"
    host_pool_name     = "hp-avd-hybrid-dev"
    arc_sp_secret_arn  = "arn:aws:secretsmanager:us-east-1:000000000000:secret:avd-arc-sp-dev-000000"
  }

  assert {
    condition     = output.avd_aws_outputs.schema == "avd-aws-outputs/v1"
    error_message = "Output schema must match avd-aws-outputs/v1."
  }

  assert {
    condition     = output.avd_aws_outputs.osFamily == "windows-11-enterprise"
    error_message = "osFamily must be single-session windows-11-enterprise."
  }

  assert {
    condition     = output.avd_aws_outputs.identityMode == "entra-joined"
    error_message = "identityMode must be entra-joined."
  }

  assert {
    condition     = output.avd_aws_outputs.fslogixStorageMode == "disabled"
    error_message = "Lab profile default should keep FSx for NetApp ONTAP disabled."
  }

  assert {
    condition     = module.compute.autoscaling_group_name == "asg-avd-hosts-dev"
    error_message = "Compute module should expose autoscaling_group_name for the 01-hybrid environment."
  }
}
