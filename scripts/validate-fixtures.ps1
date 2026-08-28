[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$fixtureRoot = Join-Path $Root 'tests\fixtures'
$required = @('source.sql', 'target.sql', 'cases.json')
$fixtures = @(Get-ChildItem -LiteralPath $fixtureRoot -Directory -ErrorAction SilentlyContinue)
$results = foreach ($fixture in $fixtures) {
    $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $fixture.FullName $_) -PathType Leaf) })
    [pscustomobject]@{
        Fixture = $fixture.Name
        Valid = $missing.Count -eq 0
        Missing = $missing
    }
}
if (($results | Where-Object { -not $_.Valid }).Count -gt 0) {
    $results | ConvertTo-Json -Depth 5
    throw 'One or more sanitized fixtures are incomplete.'
}
$results | ConvertTo-Json -Depth 5

