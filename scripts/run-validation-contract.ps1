[CmdletBinding()]
param([Parameter(Mandatory)][string]$Contract,[string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
if(-not(Test-Path $Contract)){throw "Validation contract not found: $Contract"}
$c=Get-Content $Contract -Raw|ConvertFrom-Json
foreach($p in @('sourceQuery','targetQuery')){if(-not(Test-Path (Join-Path $Root $c.$p))){throw "Contract file missing: $($c.$p)"}}
if($c.comparison.mode -notin @('exact','tolerant')){throw 'Comparison mode must be exact or tolerant.'}
[pscustomobject]@{Valid=$true;Object=$c.object;Mode=$c.comparison.mode;Status='ready-for-connected-execution'}|ConvertTo-Json

