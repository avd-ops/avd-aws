output "avd_aws_outputs" {
  description = "Structured avd-aws-outputs/v1 payload (modeled on C32 avd-gcp-outputs/v1) for avd-azure, avd-landing-zone, and avd-current-state."
  value = {
    schema               = "avd-aws-outputs/v1"
    environment          = var.environment
    region               = var.region
    profile              = var.profile
    osFamily             = "windows-11-enterprise"
    identityMode         = "entra-joined"
    vpcName              = module.network.vpc_name
    subnetName           = module.network.private_subnet_name
    egressMode           = var.egress_mode
    rdpShortpathUdp3478  = var.enable_rdp_shortpath_udp_3478
    fslogixStorageMode   = module.storage.fslogix_storage_mode
    autoScalingGroupName = module.compute.autoscaling_group_name
    sessionHostCount     = var.session_host_count
    arcResourceGroup     = var.arc_resource_group
    hostPoolName         = var.host_pool_name
  }
}
