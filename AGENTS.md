# Instructions for AI agents

For any coding agent: Claude Code, Gemini CLI, Codex and others. Read this file first, then
[CLAUDE.md](CLAUDE.md). Gemini CLI loads this file through [GEMINI.md](GEMINI.md). Where they
differ, the more specific rule wins, and the owner's own words win over all of them.

## How to make a change

- Say what you assumed. When the ask leaves a detail open, pick the reasonable default, say which,
  and keep going.
- Write the least code that does the job: no speculative features, options, or abstractions.
- Touch only what the task needs and match the style around it.
- Before you start, name the check that proves the task is done, and don't call it done until it
  passes in front of you.

## Family rules

- **No spend without the owner's exact go.** No AWS or Azure cloud run without a written cost
  estimate and the owner typing `go batch <id> $<total>`.
- **Never leave the meter running.** EC2 instances, NAT Gateways, EBS volumes, S3 staging
  objects, and FSx file systems must be torn down or scaled to `0` after smoke tests.
  `enable_fslogix_fsx` defaults to `false` in `lab` profile.
- **Never delete the last copy** of data without a checked copy elsewhere or `-DiscardLastCopy`.
- **No secrets, IDs or names.** No AWS account IDs, ARNs with real account IDs, Azure
  tenant/subscription/object/client IDs, domains, IPs, emails, secrets, or employer/customer names
  in the repo, commits, issues, or PRs. Use placeholders (`contoso.com`, `<aws-account-id>`,
  `<tenant-id>`, `10.x`).
- **Pull requests only; the owner merges.** Work on a branch and open a PR; never push directly to
  `main`.
- **Stay in your lane.** `avd-aws` owns the AWS compute, network, FSx storage, Packer image, and
  Arc onboarding plane for AVD Hybrid. Azure-side AVD host pools and workspaces live in
  `avd-azure` / `avd-landing-zone`.
- **Personal project, not for production, as is, not affiliated with the author's employer,
  Liquidware, ServiceNow, AWS or Microsoft.**
- **American English** in docs, output, and comments.

## Checks to run

```bash
terraform fmt -check -recursive
for d in modules/*/ environments/example/*/; do
  (cd "$d" && terraform init -backend=false && terraform validate && terraform test)
done
```
