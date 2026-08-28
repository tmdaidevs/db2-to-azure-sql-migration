[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$Offline,
    [switch]$PlanOnly,
    [switch]$SanitizedPilot
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'write-state.ps1') -Root $Root -Phase PREFLIGHT -Message 'Starting migration package preflight.'
& (Join-Path $PSScriptRoot 'validate-policy.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'preflight.ps1') -Root $Root -AllowOffline:($Offline -or $PlanOnly -or $SanitizedPilot)
& (Join-Path $PSScriptRoot 'detect-runtime.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'analyze-ssma.ps1') -Root $Root
& (Join-Path $PSScriptRoot 'build-manifest.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'build-dependencies.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'check-compatibility.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'validate-fixtures.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'write-state.ps1') -Root $Root -Phase ASSESSED -Message 'SSMA reports inventoried.'
& (Join-Path $PSScriptRoot 'generate-report.ps1') -Root $Root | Out-Null

if ($SanitizedPilot) {
    & (Join-Path $PSScriptRoot 'run-sanitized-pilot.ps1') -Root $Root
    exit 0
}

if ($Offline -or $PlanOnly) {
    Write-Output 'Analysis complete. No source or target database operation was performed.'
    exit 0
}

throw 'Connected execution is not enabled in this first version. Complete the SSMA driver integration after validating source, target, authentication, and cutover policy.'
