[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$envPath = Join-Path $Root '.env'
$values = @{}
if (Test-Path -LiteralPath $envPath) {
    foreach ($line in Get-Content -LiteralPath $envPath) {
        if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') {
            $values[$matches[1]] = $matches[2]
        }
    }
}

$groups = @(
    [pscustomobject]@{ Name = 'package'; Fields = @('MIGRATION_ROOT') },
    [pscustomobject]@{ Name = 'db2-source'; Fields = @('DB2_PLATFORM','DB2_HOST','DB2_PORT','DB2_DATABASE','DB2_SCHEMA_SCOPE','DB2_PROVIDER') },
    [pscustomobject]@{ Name = 'azure-target'; Fields = @('AZURE_SQL_TARGET','AZURE_SQL_SERVER','AZURE_SQL_DATABASE','AZURE_SQL_AUTH') },
    [pscustomobject]@{ Name = 'policy'; Fields = @('MIGRATION_MODE','DATA_MIGRATION_STRATEGY') },
    [pscustomobject]@{ Name = 'validation'; Fields = @('REQUIRE_BEHAVIORAL_VALIDATION') },
    [pscustomobject]@{ Name = 'cutover'; Fields = @('ALLOW_PRODUCTION_CUTOVER') }
)

$result = foreach ($group in $groups) {
    $missing = @($group.Fields | Where-Object { [string]::IsNullOrWhiteSpace($values[$_]) })
    [pscustomobject]@{
        Phase = $group.Name
        Complete = $missing.Count -eq 0
        Missing = $missing
    }
}
[pscustomobject]@{
    OnboardingComplete = (@($result | Where-Object { -not $_.Complete }).Count -eq 0)
    NextPhase = ($result | Where-Object { -not $_.Complete } | Select-Object -First 1).Phase
    Phases = $result
} | ConvertTo-Json -Depth 8

