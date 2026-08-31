[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'validate-env.ps1') -Root $Root -Connected|Out-Null
& (Join-Path $PSScriptRoot 'detect-runtime.ps1') -Root $Root|Out-Null
$values=@{};Get-Content (Join-Path $Root '.env')|%{if($_ -match '^([A-Z][A-Z0-9_]*)=(.*)$'){$values[$matches[1]]=$matches[2]}}
if(-not $values['SSMA_CONSOLE_PATH']){throw 'SSMA_CONSOLE_PATH is required.'}
if(-not(Test-Path $values['SSMA_CONSOLE_PATH'] -PathType Leaf)){throw 'SSMA_CONSOLE_PATH does not exist.'}
[pscustomobject]@{Valid=$true;Target="$($values['AZURE_SQL_SERVER'])/$($values['AZURE_SQL_DATABASE']);Provider=$($values['DB2_PROVIDER'])"}|ConvertTo-Json

