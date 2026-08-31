[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$dir=Join-Path $Root 'migration-artifacts';New-Item -ItemType Directory -Force $dir|Out-Null
$path=Join-Path $dir '.migration.lock'
if(Test-Path -LiteralPath $path){throw "Another migration run appears active: $path"}
[pscustomobject]@{pid=$PID;host=$env:COMPUTERNAME;createdAt=(Get-Date).ToUniversalTime().ToString('o')}|ConvertTo-Json|Set-Content -LiteralPath $path -Encoding utf8
Write-Output $path
