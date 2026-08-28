[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
$runId = Get-Date -Format 'yyyyMMddTHHmmssfffZ'
$runDir = Join-Path $artifactDir $runId
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
[pscustomobject]@{
    runId = $runId
    root = $Root
    runDirectory = $runDir
    startedAt = (Get-Date).ToUniversalTime().ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runDir 'run.json') -Encoding utf8
Write-Output $runDir

