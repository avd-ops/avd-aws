output "fslogix_storage_mode" {
  description = "Active FSLogix storage mode (disabled or aws-fsx-ontap)."
  value       = var.enable_fslogix_fsx ? "aws-fsx-ontap" : "disabled"
}

output "fsx_file_system_id" {
  description = "FSx for NetApp ONTAP file system ID when enabled."
  value       = var.enable_fslogix_fsx ? aws_fsx_ontap_file_system.fslogix[0].id : null
}
