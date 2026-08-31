[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent),[switch]$Execute)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'validate-connected-runtime.ps1') -Root $Root|Out-Null
$script=Join-Path $Root 'migration-artifacts\ssma-synchronize.xml'
if(-not(Test-Path $script)){throw 'Generate the approved synchronize SSMA script before baseline deployment.'}
& (Join-Path $PSScriptRoot 'validate-ssma-script.ps1') -ScriptFile $script|Out-Null
if(-not $Execute){Write-Output 'Baseline deployment plan validated. Re-run with -Execute after chat authorization.';exit 0}
& (Join-Path $PSScriptRoot 'run-ssma-stage.ps1') -Root $Root -Stage synchronize

