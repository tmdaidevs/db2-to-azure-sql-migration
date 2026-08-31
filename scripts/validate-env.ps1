[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$Connected
)

$ErrorActionPreference = 'Stop'
$envPath = Join-Path $Root '.env'
if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
    if ($Connected) { throw 'Connected execution requires .env created from chat intake.' }
    [pscustomobject]@{ Valid = $true; Mode = 'offline'; Missing = @() } | ConvertTo-Json
    exit 0
}
$values = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') { $values[$matches[1]] = $matches[2] }
}
$required = if ($Connected) {
    @('DB2_PLATFORM','DB2_HOST','DB2_DATABASE','DB2_SCHEMA_SCOPE','DB2_PROVIDER','AZURE_SQL_TARGET','AZURE_SQL_SERVER','AZURE_SQL_DATABASE','AZURE_SQL_AUTH','MIGRATION_MODE')
} else { @('MIGRATION_MODE') }
$missing = @($required | Where-Object { [string]::IsNullOrWhiteSpace($values[$_]) })
if ($missing.Count) { throw "Missing required configuration: $($missing -join ', ')" }
if ($values['MIGRATION_MODE'] -notin @('offline','staging','rehearsal','production')) { throw 'MIGRATION_MODE is invalid.' }
if ($values['AZURE_SQL_TARGET'] -and $values['AZURE_SQL_TARGET'] -notin @('database','managed-instance')) { throw 'AZURE_SQL_TARGET is invalid.' }
[pscustomobject]@{ Valid = $true; Mode = $values['MIGRATION_MODE']; Missing = @(); Target = $values['AZURE_SQL_TARGET'] } | ConvertTo-Json

