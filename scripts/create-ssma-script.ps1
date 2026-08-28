[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter(Mandatory)]
    [string]$SourceServerName,
    [Parameter(Mandatory)]
    [string]$TargetServerName,
    [Parameter()]
    [ValidateSet('assessment','convert','synchronize','migrate','all')]
    [string]$Stage = 'all'
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$projects = @(Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter '*.db2ssproj')
if ($projects.Count -ne 1) {
    throw "Expected exactly one SSMA project below input for script generation; found $($projects.Count)."
}
$project = $projects[0]
$projectFolder = $project.Directory.FullName
$projectName = $project.BaseName
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$scriptPath = Join-Path $artifactDir "ssma-$Stage.xml"
$reportDir = Join-Path $artifactDir 'ssma-reports'
New-Item -ItemType Directory -Force $reportDir | Out-Null

$commands = @(
    "<open-project project-folder=""$projectFolder"" project-name=""$projectName"" />",
    "<connect-source-database server=""$SourceServerName"" />",
    "<connect-target-database server=""$TargetServerName"" />"
)
if ($Stage -in @('assessment','all')) {
    $commands += "<generate-assessment-report object-name=""all"" object-type=""category"" verbose=""true"" report-errors=""true"" assessment-report-folder=""$reportDir"" write-summary-report-to=""$reportDir\AssessmentReport.xml"" />"
}
if ($Stage -in @('convert','all')) {
    $commands += "<convert-schema object-name=""all"" object-type=""category"" verbose=""true"" report-errors=""true"" conversion-report-folder=""$reportDir"" write-summary-report-to=""$reportDir\SchemaConversionReport.xml"" />"
}
if ($Stage -in @('synchronize','all')) {
    $commands += "<synchronize-target object-name=""all"" on-error=""fail-script"" report-errors-to=""$reportDir\TargetSynchronizationErrors.xml"" />"
}
if ($Stage -in @('migrate','all')) {
    $commands += "<migrate-data object-name=""all"" object-type=""category"" verbose=""true"" report-errors=""true"" conversion-report-folder=""$reportDir"" write-summary-report-to=""$reportDir\DataMigrationReport.xml"" />"
}
$commands += '<save-project />'
$commands += '<close-project if-modified="save" />'

$xml = @"
<?xml version="1.0" encoding="utf-8"?>
<ssma-script>
  <!-- Review server names, target, object scope, and destructive policy before execution. -->
  $($commands -join "`r`n  ")
</ssma-script>
"@
$xml | Set-Content -LiteralPath $scriptPath -Encoding utf8
[pscustomobject]@{
    Script = $scriptPath
    Project = $project.FullName
    Stage = $Stage
    SourceServerName = $SourceServerName
    TargetServerName = $TargetServerName
    RequiresReview = $true
} | ConvertTo-Json

