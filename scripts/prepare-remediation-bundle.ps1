[CmdletBinding()]
param([Parameter(Mandatory)][string]$ObjectSource,[Parameter(Mandatory)][string]$Schema,[Parameter(Mandatory)][string]$ObjectName,[string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
if(-not(Test-Path $ObjectSource)){throw "Source object not found: $ObjectSource"}
$safe=$ObjectName -replace '[^A-Za-z0-9_.-]','_';$dir=Join-Path $Root "migration-artifacts\remediation\$Schema\$safe";New-Item -ItemType Directory -Force $dir|Out-Null
Copy-Item $ObjectSource (Join-Path $dir 'source.sql') -Force
[pscustomobject]@{schemaVersion=1;schema=$Schema;object=$ObjectName;source='source.sql';status='context-ready';candidate='candidate.sql';tests='tests.json';createdAt=(Get-Date).ToUniversalTime().ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $dir 'context.json') -Encoding utf8
Write-Output $dir

