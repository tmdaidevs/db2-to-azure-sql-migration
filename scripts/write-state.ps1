[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('PREFLIGHT','ASSESSED','CONVERTED','BASELINE_DEPLOYED','REMEDIATED','CODE_VALIDATED','DATA_MIGRATED','RECONCILED','CUTOVER_READY','CUTOVER_CONFIRMED','BLOCKED')]
    [string]$Phase,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter()]
    [string]$Message = ''
)

$ErrorActionPreference = 'Stop'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
$stateFile = Join-Path $artifactDir 'migration-state.json'

$state = if (Test-Path -LiteralPath $stateFile) {
    Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
} else {
    [pscustomobject]@{ schemaVersion = 1; phase = 'PREFLIGHT'; history = @() }
}

$history = @($state.history) + [pscustomobject]@{
    phase = $Phase
    message = $Message
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
}
$newState = [pscustomobject]@{
    schemaVersion = 1
    phase = $Phase
    updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    history = $history
}
$newState | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $stateFile -Encoding utf8
$newState | ConvertTo-Json -Depth 8

