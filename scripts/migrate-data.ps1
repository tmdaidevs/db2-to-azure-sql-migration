[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent),[switch]$Execute)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'validate-connected-runtime.ps1') -Root $Root|Out-Null
$policy=Get-Content (Join-Path $Root 'config\migration-policy.json') -Raw|ConvertFrom-Json
if($policy.allowSourceWrites){throw 'Source writes are prohibited by migration policy.'}
if(-not $Execute){Write-Output 'Data migration plan validated. Re-run with -Execute after chat authorization and source quiescence/synchronization checks.';exit 0}
& (Join-Path $PSScriptRoot 'run-ssma-stage.ps1') -Root $Root -Stage migrate

