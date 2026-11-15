terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
  }
}

provider "aws" {
  region = var.region
}

module "network" {
  source = "../../../modules/network"

  environment                   = var.environment
  availability_zone             = var.availability_zone
  vpc_cidr                      = var.vpc_cidr
  private_subnet_cidr           = var.private_subnet_cidr
  public_subnet_cidr            = var.public_subnet_cidr
  egress_mode                   = var.egress_mode
  enable_rdp_shortpath_udp_3478 = var.enable_rdp_shortpath_udp_3478
}

module "storage" {
  source = "../../../modules/storage"

  environment                    = var.environment
  vpc_id                         = module.network.vpc_id
  private_subnet_id              = module.network.private_subnet_id
  session_host_security_group_id = module.network.security_group_id
  enable_fslogix_fsx             = var.enable_fslogix_fsx
}

module "compute" {
  source = "../../../modules/compute"

  environment        = var.environment
  private_subnet_id  = module.network.private_subnet_id
  security_group_id  = module.network.security_group_id
  source_ami_id      = var.source_ami_id
  instance_type      = var.instance_type
  boot_disk_size_gb  = var.boot_disk_size_gb
  session_host_count = var.session_host_count
  arc_resource_group = var.arc_resource_group
  host_pool_name     = var.host_pool_name
  arc_sp_secret_arn  = var.arc_sp_secret_arn
  user_data_ps1      = var.user_data_ps1
}
