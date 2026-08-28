[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceResult,
    [Parameter(Mandatory)]
    [string]$TargetResult,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
foreach ($path in @($SourceResult, $TargetResult)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Result file not found: $path"
    }
}

function Normalize-Value($value) {
    if ($null -eq $value) { return $null }
    if ($value -is [System.Array]) {
        return @($value | ForEach-Object { Normalize-Value $_ })
    }
    if ($value -is [pscustomobject]) {
        $item = [ordered]@{}
        foreach ($property in ($value.PSObject.Properties | Sort-Object Name)) {
            $item[$property.Name] = Normalize-Value $property.Value
        }
        return [pscustomobject]$item
    }
    return $value
}

$source = Normalize-Value (Get-Content -LiteralPath $SourceResult -Raw | ConvertFrom-Json)
$target = Normalize-Value (Get-Content -LiteralPath $TargetResult -Raw | ConvertFrom-Json)
$sourceJson = ConvertTo-Json $source -Depth 20 -Compress
$targetJson = ConvertTo-Json $target -Depth 20 -Compress
$result = [pscustomobject]@{
    comparedAt = (Get-Date).ToUniversalTime().ToString('o')
    equivalent = $sourceJson -ceq $targetJson
    sourceResult = $SourceResult
    targetResult = $TargetResult
}
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$output = Join-Path $artifactDir 'validation-comparison.json'
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $output -Encoding utf8
$result | ConvertTo-Json
if (-not $result.equivalent) { exit 2 }

