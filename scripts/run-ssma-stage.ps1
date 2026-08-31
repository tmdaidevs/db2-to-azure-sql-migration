[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('assessment','convert','synchronize','migrate','all')][string]$Stage,
    [Parameter()][string]$Root=(Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference='Stop'
$envPath=Join-Path $Root '.env'
if(-not(Test-Path $envPath)){throw 'Create .env through chat intake before connected execution.'}
$values=@{};Get-Content $envPath|%{if($_ -match '^([A-Z][A-Z0-9_]*)=(.*)$'){$values[$matches[1]]=$matches[2]}}
$exe=$values['SSMA_CONSOLE_PATH'];if([string]::IsNullOrWhiteSpace($exe)){throw 'SSMA_CONSOLE_PATH is required.'}
$script=Join-Path $Root "migration-artifacts\ssma-$Stage.xml"
if(-not(Test-Path $script)){throw "Generate the SSMA $Stage script first."}
$args=@('-s',$script)
$variable=$values['SSMA_VARIABLE_FILE'];if($variable){$args+=@('-v',$variable)}
& (Join-Path $PSScriptRoot 'invoke-ssma.ps1') -SsmaConsole $exe -ScriptFile $script -Root $Root -Arguments $args

