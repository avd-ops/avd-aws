# avd-aws

Part of [avd-ops](https://avd-ops.dev/), the open toolkit for Azure Virtual Desktop.

Amazon Web Services (AWS) session-host control plane (`avd-aws`) for **Azure Virtual Desktop (AVD) Hybrid**. Provisions AWS EC2 session hosts (Launch Template + Auto Scaling Group), VPC/NAT Gateway egress, optional Amazon FSx for NetApp ONTAP (SMB) for FSLogix, and Azure Arc + `Microsoft.AzureVirtualDesktop.CloudDeviceExtension` onboarding into an Azure-hosted AVD Hybrid host pool.

> [!WARNING]
> **Community research project. Use at your own risk. No warranty.**
>
> - This is my own personal project, built on my own time **for research and learning**. It is **not affiliated with, endorsed by or supported by my employer**, Liquidware, ServiceNow, AWS or Microsoft, and it does not represent their views, products or guidance.
> - Test it first in a dedicated lab subscription and tenant before using it in production; you are responsible for reviewing the code and validating it for your environment.
> - It is provided **"as is", without warranty of any kind**, under the [MIT License](LICENSE). You use it at your own risk.
> - **Contributions and forks are welcome and encouraged.** See [Contributing](#contributing).

## How it connects

| Direction | Repo | Relationship |
|---|---|---|
| Front door | [avd-ops](https://github.com/avd-ops/avd-ops#readme) | Overview and platform decisions |
| Orchestrator | [avd-landing-zone](https://github.com/avd-ops/avd-landing-zone#readme) | Consumes `avd_aws_outputs` (`avd-aws-outputs/v1`) alongside Azure Hybrid host pools |
| Azure sibling | [avd-azure](https://github.com/avd-ops/avd-azure#readme) | Hosts the Azure-side AVD Hybrid host pool and workspace |
| Inventory | [avd-current-state](https://github.com/avd-ops/avd-current-state#readme) | Collects Arc-enabled hybrid session host state |
| GCP sibling | [avd-gcp](https://github.com/avd-ops/avd-gcp#readme) | Companion GCP Compute Engine session-host control plane for AVD Hybrid |

## What it does

- **Networking (`modules/network`)**: Deploys a dedicated AWS VPC, private subnet (`map_public_ip_on_launch = false`), and NAT Gateway (or VPC endpoint / transit egress mode) for outbound-only TCP `443` (Azure Arc + Entra + AVD service endpoints) and optional outbound UDP `3478` (RDP Shortpath). Blocks inbound internet RDP (`3389`).
- **FSLogix Storage (`modules/storage`)**: Optional Amazon FSx for NetApp ONTAP (`enable_fslogix_fsx = false` by default in `lab` profile; Entra-joined-only estates use local profiles or Azure Files with Entra Kerberos).
- **Session Hosts (`modules/compute`)**: Deploys EC2 Launch Template + Auto Scaling Group on Nitro instances (UEFI + Nitro TPM, IMDSv2 required, encrypted EBS `gp3`) running **single-session Windows 11 Enterprise** (`win11-24h2-ent`) with **Entra ID join**, least-privilege IAM instance profile scoped only to the Arc onboarding service principal secret ARN, and idempotent Azure Arc + AVD `CloudDeviceExtension` registration (`scripts/arc-onboard.ps1`).
- **Golden Image (`docs/image-pipeline.md`, `packer/avd-win11-aws`)**: Because AWS does not publish Windows 11 Enterprise public AMIs, single-session `win11-24h2-ent` is built/exported as a generalized `.vhd` (with `WindowsAzureGuestAgent` disabled/removed before `sysprep`), staged briefly in S3, and imported via `aws ec2 import-image --license-type BYOL --boot-mode uefi` using the `vmimport` IAM role.
- **Contracts**: Emits `avd_aws_outputs` matching `avd-aws-outputs/v1` (modeled on [avd-assess](https://github.com/avd-ops/avd-assess#readme) C32 `avd-gcp-outputs/v1`) for [avd-azure](https://github.com/avd-ops/avd-azure#readme), [avd-landing-zone](https://github.com/avd-ops/avd-landing-zone#readme), and [avd-current-state](https://github.com/avd-ops/avd-current-state#readme).

## Quick start (offline validation)

```bash
terraform fmt -check -recursive
for d in modules/*/ environments/example/*/; do
  (cd "$d" && terraform init -backend=false >/dev/null && terraform validate && terraform test)
done
```

## Docs

- Image pipeline: [docs/image-pipeline.md](docs/image-pipeline.md)
- Agent instructions & guardrails: [AGENTS.md](AGENTS.md)

## Contributing

Fork it, open an issue or a pull request. Follow the family guardrails in [AGENTS.md](AGENTS.md): no AWS account IDs, tenant/subscription IDs, secrets, domains, or customer names, and propose changes via pull request only. Contributions are accepted under the [MIT License](LICENSE).

## License and disclaimer

[MIT](LICENSE). Community research project, provided as is, use at your own risk, not affiliated with the author's employer, Liquidware, ServiceNow, AWS or Microsoft.
