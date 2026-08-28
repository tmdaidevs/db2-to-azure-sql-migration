[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$artifactDir = Join-Path $Root 'migration-artifacts'
$manifestPath = Join-Path $artifactDir 'object-manifest.json'
$statePath = Join-Path $artifactDir 'migration-state.json'
$inventoryPath = Join-Path $artifactDir 'ssma-report-inventory.json'

$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    root = $Root
    state = if (Test-Path $statePath) { Get-Content $statePath -Raw | ConvertFrom-Json } else { $null }
    manifest = if (Test-Path $manifestPath) { Get-Content $manifestPath -Raw | ConvertFrom-Json } else { $null }
    ssmaReports = if (Test-Path $inventoryPath) { Get-Content $inventoryPath -Raw | ConvertFrom-Json } else { @() }
}
$output = Join-Path $artifactDir 'migration-report.json'
$report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $output -Encoding utf8
$report | ConvertTo-Json -Depth 12

