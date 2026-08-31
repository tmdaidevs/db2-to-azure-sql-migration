[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$Offline,
    [switch]$PlanOnly,
    [switch]$SanitizedPilot
)

$ErrorActionPreference = 'Stop'
$lock = & (Join-Path $PSScriptRoot 'acquire-run-lock.ps1') -Root $Root
try {
$stateScript = Join-Path $PSScriptRoot 'write-state.ps1'
function Set-Phase($phase, $message) {
    & $stateScript -Root $Root -Phase $phase -Message $message | Out-Null
}

Set-Phase 'PREFLIGHT' 'Starting stateful migration orchestration.'
& (Join-Path $PSScriptRoot 'validate-policy.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'validate-env.ps1') -Root $Root -Connected:(-not ($Offline -or $SanitizedPilot)) | Out-Null
& (Join-Path $PSScriptRoot 'preflight.ps1') -Root $Root -AllowOffline:($Offline -or $SanitizedPilot) | Out-Null
& (Join-Path $PSScriptRoot 'detect-runtime.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'analyze-ssma.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'parse-reports.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'build-manifest.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'build-dependencies.ps1') -Root $Root | Out-Null
& (Join-Path $PSScriptRoot 'check-compatibility.ps1') -Root $Root | Out-Null
Set-Phase 'ASSESSED' 'Artifacts, manifest, dependencies, and compatibility assessed.'

if ($SanitizedPilot) {
    & (Join-Path $PSScriptRoot 'run-sanitized-pilot.ps1') -Root $Root | Out-Null
    Set-Phase 'RECONCILED' 'Sanitized pilot completed.'
    & (Join-Path $PSScriptRoot 'generate-report.ps1') -Root $Root | Out-Null
    & (Join-Path $PSScriptRoot 'generate-html-report.ps1') -Root $Root | Out-Null
    exit 0
}

if ($Offline -or $PlanOnly) {
    & (Join-Path $PSScriptRoot 'generate-report.ps1') -Root $Root | Out-Null
    & (Join-Path $PSScriptRoot 'generate-html-report.ps1') -Root $Root | Out-Null
    Write-Output 'Offline orchestration completed; no connected operation was performed.'
    exit 0
}

throw 'Connected orchestration requires the runtime adapters and validated .env prerequisites.'
} finally {
    if ($lock -and (Test-Path -LiteralPath $lock)) { Remove-Item -LiteralPath $lock -Force }
}
