[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SqlFile,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$WhatIf,
    [switch]$Execute,
    [Parameter()]
    [string]$ConfirmTarget
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

if (-not $Execute) {
    throw 'SQL execution is disabled by default. Use -Execute only after reviewing the SQL and target settings.'
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $envFile) {
    if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') { $values[$matches[1]] = $matches[2] }
}
$server = $values['AZURE_SQL_SERVER']
$database = $values['AZURE_SQL_DATABASE']
if ([string]::IsNullOrWhiteSpace($server) -or [string]::IsNullOrWhiteSpace($database)) {
    throw 'AZURE_SQL_SERVER and AZURE_SQL_DATABASE are required for connected execution.'
}
if ($ConfirmTarget -ne "$server/$database") {
    throw "Target confirmation mismatch. Re-run with -ConfirmTarget '$server/$database'."
}

$arguments = @('-S', $server, '-d', $database, '-b', '-l', '30', '-i', $SqlFile)
$auth = ($values['AZURE_SQL_AUTH'] ?? 'entra').ToLowerInvariant()
if ($auth -eq 'entra') {
    $arguments += '-G'
} elseif ($auth -eq 'sql') {
    if ([string]::IsNullOrWhiteSpace($values['AZURE_SQL_USER']) -or [string]::IsNullOrWhiteSpace($values['AZURE_SQL_PASSWORD'])) {
        throw 'SQL authentication requires AZURE_SQL_USER and AZURE_SQL_PASSWORD.'
    }
    $arguments += @('-U', $values['AZURE_SQL_USER'])
    $env:SQLCMDPASSWORD = $values['AZURE_SQL_PASSWORD']
} else {
    throw "Unsupported AZURE_SQL_AUTH: $auth"
}

try {
    & $sqlcmd.Source @arguments
    if ($LASTEXITCODE -ne 0) { throw "sqlcmd failed with exit code $LASTEXITCODE." }
} finally {
    if (Test-Path Env:SQLCMDPASSWORD) { Remove-Item Env:SQLCMDPASSWORD }
}
