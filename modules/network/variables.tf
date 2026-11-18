variable "environment" {
  type        = string
  description = "Deployment environment (dev, test, prod)."
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone for the session host and NAT subnets."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.30.0.0/16"
  description = "CIDR block for the AVD Hybrid VPC."
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.30.1.0/24"
  description = "CIDR block for the private session host subnet."
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.30.0.0/24"
  description = "CIDR block for the public NAT Gateway subnet."
}

variable "egress_mode" {
  type        = string
  default     = "nat-gateway"
  description = "Outbound egress mode for Azure Arc and AVD endpoints (nat-gateway, vpc-endpoints, transit-gateway)."
  validation {
    condition     = contains(["nat-gateway", "vpc-endpoints", "transit-gateway"], var.egress_mode)
    error_message = "egress_mode must be nat-gateway, vpc-endpoints, or transit-gateway."
  }
}

variable "enable_rdp_shortpath_udp_3478" {
  type        = bool
  default     = true
  description = "Allow outbound UDP 3478 for AVD RDP Shortpath."
}
