[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$policyPath = Join-Path $Root 'config\migration-policy.json'
if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) {
    throw "Missing migration policy: $policyPath"
}

$policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
$required = @('schemaVersion', 'defaultTarget', 'objectOrder', 'requiredEvidence')
foreach ($property in $required) {
    if ($null -eq $policy.$property) {
        throw "Migration policy is missing required property: $property"
    }
}
if ($policy.defaultTarget -notin @('database', 'managed-instance')) {
    throw "Unsupported defaultTarget: $($policy.defaultTarget)"
}
if ($policy.objectOrder.Count -lt 1) {
    throw 'Migration policy must define at least one object type.'
}

[pscustomobject]@{
    Valid = $true
    SchemaVersion = $policy.schemaVersion
    DefaultTarget = $policy.defaultTarget
    ObjectOrder = @($policy.objectOrder)
} | ConvertTo-Json

