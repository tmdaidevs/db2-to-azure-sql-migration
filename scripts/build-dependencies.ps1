[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$manifestPath = Join-Path $artifactDir 'object-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    & (Join-Path $PSScriptRoot 'build-manifest.ps1') -Root $Root | Out-Null
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$known = @($manifest.objects | ForEach-Object { "$($_.Schema).$($_.Name)".ToUpperInvariant() })
$edges = [System.Collections.Generic.List[object]]::new()

foreach ($object in $manifest.objects) {
    $source = Join-Path $inputDir $object.SourceArtifact
    if (-not (Test-Path -LiteralPath $source)) { continue }
    $text = Get-Content -LiteralPath $source -Raw
    $references = [regex]::Matches($text, '(?i)\b(?:[A-Z][A-Z0-9_$#]*\.)?[A-Z][A-Z0-9_$#]*\b') |
        ForEach-Object Value |
        Where-Object { $_ -match '(?i)^(?:[A-Z][A-Z0-9_$#]*\.)?[A-Z][A-Z0-9_$#]*$' } |
        ForEach-Object { $_.ToUpperInvariant() } |
        Sort-Object -Unique
    foreach ($reference in $references) {
        $candidate = if ($reference.Contains('.')) { $reference } else {
            $matches = @($known | Where-Object { $_ -like "*.$reference" })
            if ($matches.Count -eq 1) { $matches[0] } else { $null }
        }
        $owner = "$($object.Schema).$($object.Name)".ToUpperInvariant()
        if ($candidate -and $candidate -ne $owner -and $known -contains $candidate) {
            $edges.Add([pscustomobject]@{ From = $owner; To = $candidate })
        }
    }
}

$graph = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    nodes = @($known | Sort-Object -Unique)
    edges = @($edges | Sort-Object From,To -Unique)
}
$output = Join-Path $artifactDir 'dependency-graph.json'
$graph | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $output -Encoding utf8
$graph | ConvertTo-Json -Depth 8

