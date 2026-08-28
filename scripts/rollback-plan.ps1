[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$artifactDir = Join-Path $Root 'migration-artifacts'
$statePath = Join-Path $artifactDir 'migration-state.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "No migration state exists: $statePath"
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$plan = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    currentPhase = $state.phase
    automaticDestructiveRollback = $false
    actions = @(
        'Stop the migration runner and preserve migration-artifacts.',
        'Keep the source system unchanged unless an approved cutover plan says otherwise.',
        'Restore or drop only an explicitly identified isolated target database.',
        'Re-run preflight and compare the preserved manifest and evidence before resuming.',
        'Require explicit operator confirmation before any production rollback action.'
    )
    evidence = @($state.history)
}
$output = Join-Path $artifactDir 'rollback-plan.json'
$plan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $output -Encoding utf8
$plan | ConvertTo-Json -Depth 10

