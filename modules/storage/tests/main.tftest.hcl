mock_provider "aws" {}

run "storage_disabled_by_default_plan" {
  command = plan

  variables {
    environment                    = "dev"
    vpc_id                         = "vpc-00000000000000000"
    private_subnet_id              = "subnet-00000000000000000"
    session_host_security_group_id = "sg-00000000000000000"
  }

  assert {
    condition     = output.fslogix_storage_mode == "disabled"
    error_message = "FSx for NetApp ONTAP must be disabled by default."
  }

  assert {
    condition     = length(aws_fsx_ontap_file_system.fslogix) == 0
    error_message = "No FSx file system should be planned when enable_fslogix_fsx is false."
  }
}

run "storage_fsx_enabled_plan" {
  command = plan

  variables {
    environment                    = "prod"
    vpc_id                         = "vpc-00000000000000000"
    private_subnet_id              = "subnet-00000000000000000"
    session_host_security_group_id = "sg-00000000000000000"
    enable_fslogix_fsx             = true
  }

  assert {
    condition     = output.fslogix_storage_mode == "aws-fsx-ontap"
    error_message = "fslogix_storage_mode should be aws-fsx-ontap when enabled."
  }

  assert {
    condition     = length(aws_fsx_ontap_file_system.fslogix) == 1
    error_message = "FSx ONTAP file system should be planned when enabled."
  }
}
