<#
.SYNOPSIS
    Onboards an AWS EC2 Windows 11 Enterprise host to Entra ID and Azure Arc.
.DESCRIPTION
    Idempotent first-boot onboarding script for AVD Hybrid on AWS:
    1. Optionally applies an Entra ID bulk-enrollment provisioning package (.ppkg) if not already Entra-joined.
    2. Installs AzureConnectedMachineAgent if absent (uses pre-staged MSI if present, else downloads).
    3. Fetches the scoped Arc service principal secret from AWS Secrets Manager (via the EC2 instance profile)
       and trims any trailing CR/LF, or accepts -ServicePrincipalSecret out-of-band.
    4. Connects the host to the target Azure Arc Resource Group.
    5. Run scripts/Register-AvdHybridExtension.ps1 from the Azure control plane to install CloudDeviceExtension.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$ResourceGroup,

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string]$ServicePrincipalId,

    [string]$ArcSpSecretArn,

    [string]$AwsRegion,

    [SecureString]$ServicePrincipalSecret,

    [string]$EntraProvisioningPackagePath,

    [string]$ProviderTag = 'hybrid-aws'
)

$ErrorActionPreference = 'Stop'

# Ensure AWS CLI v2 is discoverable when running under EC2Launch UserData
$awsCliDir = 'C:\Program Files\Amazon\AWSCLIV2'
if ((Test-Path $awsCliDir) -and (($env:PATH -split ';') -notcontains $awsCliDir)) {
    $env:PATH = "$awsCliDir;$env:PATH"
}

# 1. Entra ID join (bulk-enrollment .ppkg) if not already joined
if ($EntraProvisioningPackagePath -and (Test-Path $EntraProvisioningPackagePath)) {
    $dsreg = & dsregcmd.exe /status | Out-String
    if ($dsreg -notmatch 'AzureAdJoined\s*:\s*YES') {
        Install-ProvisioningPackage -PackagePath $EntraProvisioningPackagePath -QuietInstall
    }
}

# 2. Install Azure Connected Machine Agent if absent
$azcmagent = 'C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe'
if (-not (Test-Path $azcmagent)) {
    $preStagedMsi = 'C:\Windows\Temp\AzureConnectedMachineAgent.msi'
    $msiPath = if (Test-Path $preStagedMsi) {
        $preStagedMsi
    } else {
        $dl = Join-Path $env:TEMP 'AzureConnectedMachineAgent.msi'
        Invoke-WebRequest -Uri 'https://aka.ms/AzureConnectedMachineAgent' -OutFile $dl
        $dl
    }
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait
}

# 3. Connect to Azure Arc if not already Connected
$status = $null
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $showOutput = & $azcmagent show --json 2>$null
    if ($LASTEXITCODE -eq 0 -and $showOutput) {
        $status = $showOutput | ConvertFrom-Json
    }
} finally {
    $ErrorActionPreference = $prevEap
}
if (-not $status -or $status.status -ne 'Connected') {
    $plainSpSecret = $null

    if ($ArcSpSecretArn) {
        $regionArgs = @()
        if ($AwsRegion) {
            $regionArgs = @('--region', $AwsRegion)
        }

        if (Get-Command Get-SECSecretValue -ErrorAction SilentlyContinue) {
            $smParams = @{ SecretId = $ArcSpSecretArn }
            if ($AwsRegion) { $smParams['Region'] = $AwsRegion }
            $rawSecret = (Get-SECSecretValue @smParams).SecretString
        } elseif (Get-Command aws -ErrorAction SilentlyContinue) {
            $rawSecret = & aws secretsmanager get-secret-value `
                --secret-id $ArcSpSecretArn `
                @regionArgs `
                --query SecretString `
                --output text
            if ($LASTEXITCODE -ne 0) {
                throw "aws secretsmanager get-secret-value failed with exit code $LASTEXITCODE."
            }
        } else {
            throw 'Neither AWS.Tools.SecretsManager (Get-SECSecretValue) nor AWS CLI (aws) is installed.'
        }

        $plainSpSecret = ([string]$rawSecret).Trim()
    } elseif ($ServicePrincipalSecret) {
        $bstrSp = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalSecret)
        try {
            $plainSpSecret = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstrSp)).Trim()
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrSp)
        }
    } else {
        throw 'Provide either -ArcSpSecretArn or -ServicePrincipalSecret.'
    }

    if ([string]::IsNullOrWhiteSpace($plainSpSecret)) {
        throw 'Resolved Azure Arc service principal secret is empty.'
    }

    try {
        & $azcmagent connect `
            --service-principal-id $ServicePrincipalId `
            --service-principal-secret $plainSpSecret `
            --subscription-id $SubscriptionId `
            --resource-group $ResourceGroup `
            --tenant-id $TenantId `
            --location $Location `
            --tags "avd-ops=$ProviderTag"
        if ($LASTEXITCODE -ne 0) {
            throw "azcmagent connect failed with exit code $LASTEXITCODE."
        }
    } finally {
        $plainSpSecret = $null
    }
}

Write-Output "Azure Arc agent connected for $env:COMPUTERNAME in $ResourceGroup."
