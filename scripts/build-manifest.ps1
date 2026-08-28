[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
if (-not (Test-Path -LiteralPath $inputDir -PathType Container)) {
    throw "Missing input directory: $inputDir"
}

$records = [System.Collections.Generic.List[object]]::new()
$sourceFiles = Get-ChildItem -LiteralPath $inputDir -Recurse -File |
    Where-Object { $_.Extension -eq '.sql' -or $_.Name -eq 'src.sql.txt' }

foreach ($file in $sourceFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($text)) { continue }
    $relative = $file.FullName.Substring($inputDir.Length + 1)

    $matches = [regex]::Matches(
        $text,
        '(?is)\bCREATE\s+(?:OR\s+REPLACE\s+)?(?<type>FUNCTION|PROCEDURE|TRIGGER|VIEW|TABLE|SEQUENCE)\s+(?:"?(?<schema>[A-Za-z0-9_$#]+)"?\.)?"?(?<name>[A-Za-z0-9_$#]+)"?'
    )
    foreach ($match in $matches) {
        $records.Add([pscustomobject]@{
            Schema = $match.Groups['schema'].Value
            Name = $match.Groups['name'].Value
            Type = $match.Groups['type'].Value.ToLowerInvariant()
            SourceArtifact = $relative
            SourceBytes = $file.Length
            SourceLastWriteTime = $file.LastWriteTime.ToString('o')
            Status = 'discovered'
        })
    }
}

$records = @($records | Sort-Object Schema,Type,Name,SourceArtifact -Unique)
$manifest = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    inputDirectory = $inputDir
    objectCount = $records.Count
    objects = $records
}
$output = Join-Path $artifactDir 'object-manifest.json'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $output -Encoding utf8
$manifest | ConvertTo-Json -Depth 8
