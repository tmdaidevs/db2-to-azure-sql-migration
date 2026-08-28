[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Capability,
    [Parameter(Mandatory)]
    [ValidateSet('configuration','adapter','parser','conversion-pattern','validator','target-feature','unsafe-operation','unknown')]
    [string]$Category,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter()]
    [string]$Evidence = '',
    [Parameter()]
    [switch]$ApplySafeExtension
)

$ErrorActionPreference = 'Stop'
$id = ((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + ($Capability -replace '[^A-Za-z0-9-]', '-')).ToLowerInvariant()
$dir = Join-Path (Join-Path $Root 'migration-artifacts') "capability-gaps\$id"
New-Item -ItemType Directory -Force $dir | Out-Null

$safeToExtend = $Category -in @('configuration','adapter','parser','conversion-pattern','validator')
$status = if ($ApplySafeExtension -and $safeToExtend) { 'proposal-created-safe-extension-requires-review' } elseif ($safeToExtend) { 'proposal-created' } else { 'blocked-for-explicit-decision' }
$proposal = [pscustomobject]@{
    schemaVersion = 1
    id = $id
    capability = $Capability
    category = $Category
    evidence = $Evidence
    status = $status
    proposedChanges = @(
        'Add the smallest reusable implementation under scripts, config, tests, or the skill package.',
        'Preserve authentication, validation, confirmation, and rollback gates.',
        'Add a sanitized fixture and a focused quality check.',
        'Update the skill and evidence report with the new capability.'
    )
    forbiddenChanges = @(
        'Do not remove safety gates or broaden permissions.',
        'Do not create credentials or access production implicitly.',
        'Do not invent source semantics or silently select an unsupported target feature.'
    )
    rollback = 'Remove the scoped extension files and restore the prior skill version; preserve this proposal as evidence.'
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
}
$output = Join-Path $dir 'proposal.json'
$proposal | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $output -Encoding utf8
$proposal | ConvertTo-Json -Depth 10

