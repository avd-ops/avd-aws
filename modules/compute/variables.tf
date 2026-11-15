variable "environment" {
  type        = string
  description = "Deployment environment (dev, test, prod)."
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID for the EC2 Auto Scaling Group."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to AVD Hybrid session hosts."
}

variable "source_ami_id" {
  type        = string
  description = "Imported BYOL Windows 11 Enterprise (win11-24h2-ent) AMI ID."
}

variable "instance_type" {
  type        = string
  default     = "m6i.xlarge"
  description = "Nitro EC2 instance type (UEFI + Nitro TPM) for Windows 11 Enterprise session hosts."
}

variable "boot_disk_size_gb" {
  type        = number
  default     = 128
  description = "Encrypted gp3 root EBS volume size in GiB."
}

variable "session_host_count" {
  type        = number
  default     = 1
  description = "Desired number of AVD Hybrid session hosts in the Auto Scaling Group."
}

variable "arc_resource_group" {
  type        = string
  description = "Azure Resource Group where EC2 instances project as Azure Arc-enabled servers."
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
