packer {
  required_version = ">= 1.10.0"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_id" {
  type        = string
  description = "Imported BYOL Windows 11 Enterprise (win11-24h2-ent) AMI ID (see docs/image-pipeline.md)."
}

variable "instance_type" {
  type    = string
  default = "m6i.xlarge"
}

variable "ami_name_prefix" {
  type    = string
  default = "avd-win11-ent"
}

source "amazon-ebs" "avd_win11" {
  region                      = var.aws_region
  source_ami                  = var.source_ami_id
  instance_type               = var.instance_type
  ami_name                    = "${var.ami_name_prefix}-${formatdate("YYYYMMDDhhmm", timestamp())}"
  communicator                = "winrm"
  winrm_username              = "Administrator"
  winrm_use_ssl               = true
  winrm_insecure              = true
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 128
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.avd_win11"]

  provisioner "powershell" {
    inline = [
      "Write-Output 'Pre-staging FSLogix and Azure Connected Machine Agent prerequisites for AVD Hybrid on AWS.'",
      "Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'C:\\Windows\\Temp\\FSLogixAppsSetup.zip'",
      "Invoke-WebRequest -Uri 'https://aka.ms/AzureConnectedMachineAgent' -OutFile 'C:\\Windows\\Temp\\AzureConnectedMachineAgent.msi'"
    ]
  }
}
