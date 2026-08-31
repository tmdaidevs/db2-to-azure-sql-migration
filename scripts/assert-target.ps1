[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent),[Parameter(Mandatory)][string]$Target)
$ErrorActionPreference='Stop'
$envPath=Join-Path $Root '.env'
if(-not(Test-Path -LiteralPath $envPath)){throw 'Missing .env.'}
$line=Get-Content $envPath|Where-Object {$_ -match '^AZURE_SQL_SERVER_EXPECTED='}|Select-Object -First 1
$expected=if($line){$line.Substring($line.IndexOf('=')+1)}else{$null}
if([string]::IsNullOrWhiteSpace($expected)){throw 'AZURE_SQL_SERVER_EXPECTED must be set before target execution.'}
if($Target -ne $expected){throw "Target identity mismatch. Expected '$expected', received '$Target'."}
[pscustomobject]@{Valid=$true;Target=$Target}|ConvertTo-Json
