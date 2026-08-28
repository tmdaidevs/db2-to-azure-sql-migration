[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$example = Join-Path $Root '.env.example'
$destination = Join-Path $Root '.env'
if (-not (Test-Path -LiteralPath $example -PathType Leaf)) {
    throw "Missing .env.example: $example"
}
if ((Test-Path -LiteralPath $destination) -and -not $Force) {
    throw "$destination already exists. Use -Force only to replace it."
}

$values = [ordered]@{}
foreach ($line in Get-Content -LiteralPath $example) {
    if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') {
        $name = $matches[1]
        $default = $matches[2]
        $prompt = if ($default) { "$name [$default]" } else { $name }
        $value = Read-Host $prompt
        $values[$name] = if ([string]::IsNullOrWhiteSpace($value)) { $default } else { $value }
    }
}

$content = foreach ($line in Get-Content -LiteralPath $example) {
    if ($line -match '^\s*([A-Z][A-Z0-9_]*)=(.*)$') {
        "$($matches[1])=$($values[$matches[1]])"
    } else {
        $line
    }
}
$content | Set-Content -LiteralPath $destination -Encoding utf8
Write-Output "Created local configuration: $destination"
Write-Output 'Review the file locally. It is ignored by Git and must never be pasted into chat or committed.'

