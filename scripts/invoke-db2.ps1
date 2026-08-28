[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$QueryFile,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $Root '.env'
if (-not (Test-Path -LiteralPath $envFile -PathType Leaf)) {
    throw 'Missing .env. DB2 execution requires the interactive intake.'
}
if (-not (Test-Path -LiteralPath $QueryFile -PathType Leaf)) {
    throw "Query file not found: $QueryFile"
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $envFile) {
    if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') { $values[$matches[1]] = $matches[2] }
}
$provider = ($values['DB2_PROVIDER'] ?? 'auto').ToLowerInvariant()
$connectionString = $values['DB2_CONNECTION_STRING']
if ([string]::IsNullOrWhiteSpace($connectionString)) {
    throw 'DB2_CONNECTION_STRING is required for direct source validation.'
}
if ($provider -eq 'db2-client') {
    throw 'Direct Db2 Client Provider execution requires the SSMA provider adapter; use SSMA for source extraction or configure ole-db.'
}
if ($provider -notin @('auto','ole-db')) {
    throw "Unsupported DB2_PROVIDER: $provider"
}

$query = Get-Content -LiteralPath $QueryFile -Raw
if ($query -match '(?is)\b(INSERT|UPDATE|DELETE|MERGE|DROP|ALTER|CREATE|CALL)\b') {
    throw 'Only read-only DB2 validation queries are allowed by this adapter.'
}
if ($WhatIf) {
    [pscustomobject]@{ Provider = 'ole-db'; QueryFile = $QueryFile; ReadOnly = $true } | ConvertTo-Json
    exit 0
}

$connection = New-Object System.Data.OleDb.OleDbConnection($connectionString)
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $command.CommandTimeout = 300
    $adapter = New-Object System.Data.OleDb.OleDbDataAdapter($command)
    $table = New-Object System.Data.DataTable
    [void]$adapter.Fill($table)
    $rows = foreach ($row in $table.Rows) {
        $item = [ordered]@{}
        foreach ($column in $table.Columns) { $item[$column.ColumnName] = $row[$column.ColumnName] }
        [pscustomobject]$item
    }
    @($rows) | ConvertTo-Json -Depth 8
} finally {
    $connection.Dispose()
}

