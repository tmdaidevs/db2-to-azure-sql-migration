[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$files = @(Get-ChildItem -LiteralPath $inputDir -Recurse -File | Where-Object { $_.Name -eq 'src.sql.txt' -or $_.Extension -eq '.sql' })
$signals = [System.Collections.Generic.List[object]]::new()
$patterns = [ordered]@{
    'cross-database' = '(?i)\b(?:database|catalog)\s*\.\s*[A-Za-z_][A-Za-z0-9_]*\s*\.'
    'linked-server' = '(?i)\blinked\s*server\b|\bOPENQUERY\b|\bOPENDATASOURCE\b'
    'sql-agent' = '(?i)\b(?:SQLAgent|sp_add_job|job\s+schedule)\b'
    'clr' = '(?i)\bCREATE\s+ASSEMBLY\b|\bEXTERNAL\s+NAME\b'
    'db2-compatibility-helper' = '(?i)\bssma_db2\b'
    'dynamic-sql' = '(?i)\b(?:EXECUTE|PREPARE)\b.*(?:\+|\|\|)'
    'transaction-control' = '(?i)\b(?:COMMIT|ROLLBACK|SAVEPOINT)\b'
}
foreach ($file in $files) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($name in $patterns.Keys) {
        if ($text -match $patterns[$name]) {
            $signals.Add([pscustomobject]@{
                Signal = $name
                Artifact = $file.FullName.Substring($inputDir.Length + 1)
            })
        }
    }
}
$signalNames = @($signals | Select-Object -ExpandProperty Signal -Unique)
$recommendation = if ($signalNames | Where-Object { $_ -in @('cross-database','linked-server','sql-agent','clr') }) {
    'managed-instance-review-required'
} else {
    'azure-sql-database-compatible-until-proven-otherwise'
}
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    recommendation = $recommendation
    signals = @($signals)
    note = 'This is a screening result; confirm each signal against the selected Azure SQL target and application architecture.'
}
$output = Join-Path $artifactDir 'compatibility-assessment.json'
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $output -Encoding utf8
$result | ConvertTo-Json -Depth 8

