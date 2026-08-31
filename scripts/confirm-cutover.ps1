[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter(Mandatory)][ValidateSet('STAGE-VALIDATED')][string]$ValidationGate,
    [Parameter(Mandatory)][string]$Confirmation
)
$ErrorActionPreference='Stop'
if($ValidationGate -ne 'STAGE-VALIDATED'){throw 'Staging validation must pass before cutover.'}
if($Confirmation -cne 'CUTOVER-APPROVED'){throw 'Cutover requires exact confirmation: CUTOVER-APPROVED'}
$envPath=Join-Path $Root '.env'
if(-not(Test-Path $envPath)){throw 'Missing .env.'}
$allowed=(Get-Content $envPath|Where-Object {$_ -match '^ALLOW_PRODUCTION_CUTOVER='}) -join ''
if($allowed -ne 'ALLOW_PRODUCTION_CUTOVER=true'){throw 'ALLOW_PRODUCTION_CUTOVER=true is required.'}
[pscustomobject]@{Approved=$true;ConfirmedAt=(Get-Date).ToUniversalTime().ToString('o')}|ConvertTo-Json
