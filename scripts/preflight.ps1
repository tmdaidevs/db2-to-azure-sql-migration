[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$AllowOffline
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $Root '.env'
$exampleFile = Join-Path $Root '.env.example'
$inputDir = Join-Path $Root 'input'

if (-not (Test-Path -LiteralPath $exampleFile)) {
    throw "Missing .env.example: $exampleFile"
}

if (-not (Test-Path -LiteralPath $envFile)) {
    if ($AllowOffline) {
        Write-Output 'Offline preflight: .env is not required.'
    } else {
        throw "Missing .env. Copy .env.example to .env and complete the interactive intake first."
    }
}

if (-not (Test-Path -LiteralPath $inputDir -PathType Container)) {
    throw "Missing input directory: $inputDir"
}

$projectFiles = @(Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter '*.db2ssproj' -ErrorAction SilentlyContinue)
$reportFiles = @(Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter 'report.xml' -ErrorAction SilentlyContinue)

if ($projectFiles.Count -eq 0 -and $reportFiles.Count -eq 0) {
    if ($AllowOffline) {
        Write-Warning "No SSMA project or report.xml was found below $inputDir. The sanitized package is ready for a customer upload."
    } else {
        throw "No SSMA project or report.xml was found below $inputDir."
    }
}

$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

[pscustomobject]@{
    Root = $Root
    InputDirectory = $inputDir
    EnvironmentFilePresent = Test-Path -LiteralPath $envFile
    SSMAProjects = $projectFiles.Count
    Reports = $reportFiles.Count
    ArtifactDirectory = $artifactDir
} | ConvertTo-Json
