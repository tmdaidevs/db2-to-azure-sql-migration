[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $Root '.env'
$values = @{}
if (Test-Path -LiteralPath $envFile) {
    foreach ($line in Get-Content -LiteralPath $envFile) {
        if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') { $values[$matches[1]] = $matches[2] }
    }
}

$ssmaPath = $values['SSMA_CONSOLE_PATH']
$ssma = if ($ssmaPath) { Test-Path -LiteralPath $ssmaPath -PathType Leaf } else { $null -ne (Get-Command SSMAConsole.exe -ErrorAction SilentlyContinue) }
$provider = if ($values['DB2_PROVIDER']) { $values['DB2_PROVIDER'] } else { 'auto' }
if ($provider -notin @('auto', 'db2-client', 'ole-db')) {
    throw "DB2_PROVIDER must be auto, db2-client, or ole-db."
}

[pscustomobject]@{
    SSMAConsoleDetected = $ssma
    SSMAConsolePath = $ssmaPath
    Db2ProviderSelection = $provider
    Db2ClientPathConfigured = [bool]$values['DB2_CLIENT_PATH']
    SqlcmdDetected = $null -ne (Get-Command sqlcmd -ErrorAction SilentlyContinue)
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    ReadyForOfflineAnalysis = $true
    ReadyForConnectedExecution = [bool]$ssma
} | ConvertTo-Json

