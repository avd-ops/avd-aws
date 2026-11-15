# Image Pipeline Spec: Azure-Built Windows 11 Enterprise → AWS BYOL AMI

AWS public Windows AMIs only publish Windows Server images. Because **AVD Hybrid** does not support Windows 11 Enterprise multi-session, Entra-only Windows 11 Enterprise (single-session) session hosts on AWS must use a **custom BYOL imported AMI**.

## Pipeline Overview

1. **Build in Azure (`win11-24h2-ent`)**
   - **Base SKU**: Single-session `microsoftwindowsdesktop:windows-11:win11-24h2-ent:latest` (never `win11-24h2-ent-ms`).
   - **Pre-`sysprep` AWS prerequisites**:
     - Install **EC2Launch v2**, **AWS CLI v2** (or `AWS.Tools.SecretsManager` for `scripts/arc-onboard.ps1`), and the **AWS ENA driver**.
     - Stage `AzureConnectedMachineAgent.msi` (and optionally WDOT optimization), then **disable and remove `WindowsAzureGuestAgent`** before generalizing so the VM does not poll Azure IMDS (`169.254.169.254`) from AWS.
     - Run `EC2Launch.exe reset --clean` before `sysprep` so `.run-once` is cleared and `EC2Launch v2` executes `UserData` on first boot.
   - **Generalize**: Include an `Unattend.xml` with `SkipMachineOOBE=true` and `SkipUserOOBE=true` (so Windows 11 does not pause on the interactive OOBE screen on AWS), run `sysprep /generalize /oobe /shutdown /mode:vm /unattend:<path-to-Unattend.xml>`, and export a fixed-size `.vhd` page blob.

2. **Stage `.vhd` in S3 (Short-Lived)**
   - Create or use a private, encrypted S3 staging bucket in the target AWS region.
   - Copy the generalized `.vhd` from Azure Storage (via short-lived SAS URL) using `azcopy` to an ephemeral staging volume (single-stream `curl` resets on large VHDs), then upload to S3 with `aws s3 cp` and verify the exact byte count.
   - Revoke the SAS token and delete the Azure staging VHD/snapshot (and any ephemeral transfer disk) immediately after transfer.

3. **Import into EC2 as BYOL UEFI AMI**
   - **Prerequisites**: Ensure the `vmimport` IAM service role exists with `s3:GetObject` / `s3:GetBucketLocation` / `s3:ListBucket` on the staging bucket and `ec2:ModifySnapshotAttribute` / `ec2:CopySnapshot` / `ec2:RegisterImage` / `ec2:Describe*`.
   - **Recommended path (`import-snapshot` + `register-image`)**: `aws ec2 import-image` stalled at `62% booting` on `win11-24h2-ent`; use `import-snapshot` followed by `register-image` instead:
     ```bash
     aws ec2 import-snapshot \
       --description "AVD Hybrid win11-24h2-ent" \
       --disk-container '{
         "Description": "win11-24h2-ent",
         "Format": "VHD",
         "UserBucket": {
           "S3Bucket": "<staging-bucket>",
           "S3Key": "avd-win11-24h2-ent.vhd"
         }
       }'
     ```
   - Poll `aws ec2 describe-import-snapshot-tasks --import-task-ids <task-id>` until `Status == "completed"`, then register the AMI from the resulting `<snapshot-id>`:
     ```bash
     aws ec2 register-image \
       --name "avd-win11-24h2-ent-byol-$(date +%Y%m%d)" \
       --architecture x86_64 \
       --virtualization-type hvm \
       --root-device-name /dev/sda1 \
       --boot-mode uefi \
       --tpm-support v2.0 \
       --ena-support \
       --block-device-mappings '[{
         "DeviceName": "/dev/sda1",
         "Ebs": {
           "SnapshotId": "<snapshot-id>",
           "VolumeType": "gp3",
           "DeleteOnTermination": true
         }
       }]'
     ```
   - **Delete the `.vhd` object from S3 immediately** once the AMI is `available` so no idle S3 storage cost remains.

4. **Optional Packer Layer (`packer/avd-win11-aws`) & Deploy (`01-hybrid`)**
   - Optionally bake `AzureConnectedMachineAgent.msi` and `FSLogixAppsSetup.zip` on top of the imported BYOL AMI with `packer/avd-win11-aws/avd-win11.pkr.hcl`.
   - Pass the resulting AMI ID as `source_ami_id` to `environments/example/01-hybrid` (with `enable_fslogix_fsx = false` for local profiles).
   - **Entra ID join**: Pass a bulk-enrollment provisioning package (`.ppkg`) to `scripts/arc-onboard.ps1 -EntraProvisioningPackagePath`.
   - **Secrets & `CloudDeviceExtension`**: Store the scoped Arc onboarding SP secret in AWS Secrets Manager (`arc_sp_secret_arn`), never in EC2 User Data. Once `azcmagent` reports `Connected`, run `scripts/Register-AvdHybridExtension.ps1` from Azure Cloud Shell to install `Microsoft.AzureVirtualDesktop.CloudDeviceExtension`.

## Licensing & Compliance Note

- Verify Microsoft Windows client BYOL licensing terms (e.g., AWS Dedicated Hosts vs. shared tenancy) before any production deployment.
