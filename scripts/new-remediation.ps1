[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Schema,
    [Parameter(Mandatory)]
    [string]$ObjectName,
    [Parameter(Mandatory)]
    [ValidateSet('function','procedure','trigger','type','view','other')]
    [string]$ObjectType,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$safe = ($ObjectName -replace '[^A-Za-z0-9_.-]', '_')
$dir = Join-Path (Join-Path $Root 'migration-artifacts') "remediation\$Schema\$safe"
New-Item -ItemType Directory -Force $dir | Out-Null
$record = [pscustomobject]@{
    schemaVersion = 1
    schema = $Schema
    objectName = $ObjectName
    objectType = $ObjectType
    status = 'candidate-required'
    sourceDefinition = 'source.sql'
    ssmaDiagnostics = 'ssma-diagnostics.json'
    promptInput = 'prompt-input.json'
    candidates = @()
    acceptedCandidate = $null
    rejectedCandidates = @()
    assumptions = @()
    reviewer = $null
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
}
$record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $dir 'remediation.json') -Encoding utf8
[pscustomobject]@{ Directory = $dir; Record = Join-Path $dir 'remediation.json' } | ConvertTo-Json

