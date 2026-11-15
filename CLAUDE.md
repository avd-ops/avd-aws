@AGENTS.md

# avd-aws

AWS compute, network, FSLogix storage, and Azure Arc onboarding control plane for AVD Hybrid.

## Key constraints

- AVD Hybrid supports single-session Windows 10/11 Enterprise or Windows Server 2016–2025;
  Windows 10/11 Enterprise multi-session is unsupported.
- MVP targets single-session Windows 11 Enterprise (`win11-24h2-ent`) + Entra ID join (no AD DS
  or AWS Managed Microsoft AD required) and local profiles by default (`enable_fslogix_fsx = false`).
- AVD Autoscale, Start VM on Connect, and Azure power management are unsupported on Hybrid;
  use Auto Scaling Group scheduled actions or `desired_capacity = 0` outside active hours.
- Never place secrets in EC2 User Data; grant the instance profile `secretsmanager:GetSecretValue`
  scoped strictly to the Arc onboarding service principal secret ARN.
- Require IMDSv2 (`http_tokens = "required"`) and encrypted EBS `gp3` on all session hosts.
- All Terraform tests must run offline with `mock_provider "aws" {}` (`terraform test`).
