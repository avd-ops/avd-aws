variable "environment" {
  type        = string
  description = "Deployment environment (dev, test, prod)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where FSx for NetApp ONTAP is deployed when enabled."
}

variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID for FSx for NetApp ONTAP ENI."
}

variable "session_host_security_group_id" {
  type        = string
  default     = ""
  description = "Security group ID of the AVD session hosts allowed to reach SMB (445/tcp)."
}

variable "enable_fslogix_fsx" {
  type        = bool
  default     = false
  description = "Enable Amazon FSx for NetApp ONTAP SMB storage for FSLogix profiles (disabled by default in lab)."
}

variable "deployment_type" {
  type        = string
  default     = "SINGLE_AZ_1"
  description = "FSx ONTAP deployment type (SINGLE_AZ_1 or MULTI_AZ_1)."
  validation {
    condition     = contains(["SINGLE_AZ_1", "MULTI_AZ_1"], var.deployment_type)
    error_message = "deployment_type must be SINGLE_AZ_1 or MULTI_AZ_1."
  }
}

variable "storage_capacity_gib" {
  type        = number
  default     = 1024
  description = "FSx ONTAP SSD storage capacity in GiB (minimum 1024 GiB)."
}

variable "throughput_capacity_mbps" {
  type        = number
  default     = 128
  description = "FSx ONTAP throughput capacity in MB/s."
}

variable "volume_size_mb" {
  type        = number
  default     = 204800
  description = "FSx ONTAP FSLogix volume size in MB."
}
