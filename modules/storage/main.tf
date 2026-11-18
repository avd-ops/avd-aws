terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
  }
}

resource "aws_security_group" "fsx" {
  count                  = var.enable_fslogix_fsx ? 1 : 0
  name                   = "avd-fsx-sg-${var.environment}"
  description            = "Allow SMB (445/tcp) from AVD session hosts to Amazon FSx for NetApp ONTAP."
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  ingress {
    description     = "SMB from AVD session hosts"
    from_port       = 445
    to_port         = 445
    protocol        = "tcp"
    security_groups = var.session_host_security_group_id != "" ? [var.session_host_security_group_id] : []
  }

  tags = {
    Name        = "sg-avd-fsx-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_fsx_ontap_file_system" "fslogix" {
  count               = var.enable_fslogix_fsx ? 1 : 0
  storage_capacity    = var.storage_capacity_gib
  subnet_ids          = [var.private_subnet_id]
  deployment_type     = var.deployment_type
  throughput_capacity = var.throughput_capacity_mbps
  preferred_subnet_id = var.private_subnet_id
  security_group_ids  = [aws_security_group.fsx[0].id]

  tags = {
    Name        = "fsx-avd-fslogix-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "fslogix" {
  count                      = var.enable_fslogix_fsx ? 1 : 0
  file_system_id             = aws_fsx_ontap_file_system.fslogix[0].id
  name                       = "svm-avd-fslogix-${var.environment}"
  root_volume_security_style = "NTFS"

  tags = {
    Name        = "svm-avd-fslogix-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_fsx_ontap_volume" "fslogix" {
  count                      = var.enable_fslogix_fsx ? 1 : 0
  name                       = "vol_fslogix_profiles"
  junction_path              = "/fslogix-profiles"
  size_in_megabytes          = var.volume_size_mb
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.fslogix[0].id
  security_style             = "NTFS"

  tags = {
    Name        = "vol-avd-fslogix-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}
