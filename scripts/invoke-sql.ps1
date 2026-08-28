[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SqlFile,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $Root '.env'
if (-not (Test-Path -LiteralPath $envFile -PathType Leaf)) {
    throw 'Missing .env. Connected SQL execution requires the interactive intake.'
}
if (-not (Test-Path -LiteralPath $SqlFile -PathType Leaf)) {
    throw "SQL file not found: $SqlFile"
}

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    throw 'sqlcmd was not found. Install the approved SQL command-line client before connected execution.'
}

if ($WhatIf) {
    [pscustomobject]@{ Action = 'validate'; SqlFile = $SqlFile; Executable = $sqlcmd.Source } | ConvertTo-Json
    exit 0
}

throw 'Direct SQL execution is disabled in the first version until authentication and target parameters are explicitly wired and validated.'

