variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region."
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "AWS availability zone."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment (dev, test, prod)."
}

variable "profile" {
  type        = string
  default     = "lab"
  description = "Cost/guardrail profile (lab or enterprise)."
  validation {
    condition     = contains(["lab", "enterprise"], var.profile)
    error_message = "profile must be lab or enterprise."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.30.1.0/24"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.30.0.0/24"
}

variable "egress_mode" {
  type    = string
  default = "nat-gateway"
}

variable "enable_rdp_shortpath_udp_3478" {
  type    = bool
  default = true
}

variable "enable_fslogix_fsx" {
  type    = bool
  default = false
}

variable "instance_type" {
  type    = string
  default = "m6i.xlarge"
}

variable "boot_disk_size_gb" {
  type    = number
  default = 128
}

variable "source_ami_id" {
  type        = string
  description = "Imported BYOL Windows 11 Enterprise (win11-24h2-ent) AMI ID."
}

variable "session_host_count" {
  type    = number
  default = 1
}

variable "arc_resource_group" {
  type        = string
  description = "Azure Resource Group for Arc-enabled servers."
}

variable "host_pool_name" {
  type        = string
  description = "Azure AVD Hybrid host pool name."
}

variable "arc_sp_secret_arn" {
  type        = string
  default     = ""
  description = "Optional AWS Secrets Manager ARN holding the scoped Azure Arc onboarding SP secret."
}

variable "user_data_ps1" {
  type        = string
  default     = ""
  description = "Optional PowerShell User Data script (<powershell>...</powershell>) for first-boot Entra/Arc onboarding (never embed secrets)."
}
