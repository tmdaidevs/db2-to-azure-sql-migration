[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

$reports = Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter 'report.xml' |
    Sort-Object LastWriteTime

$objects = [System.Collections.Generic.List[object]]::new()
foreach ($report in $reports) {
    try {
        [xml]$xml = Get-Content -LiteralPath $report.FullName -Raw
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace('ss', 'urn:schemas-microsoft-com:office:spreadsheet')
        $workbook = $xml.SelectSingleNode('//ss:Workbook', $ns)
        $summary = $xml.SelectSingleNode('//ss:Worksheet[@ss:Name="Detailed Assessment"]', $ns)
        $categoryRows = @()
        $errorRows = @()
        $warningRows = @()
        foreach ($name in @('Objects by Categories', 'Error Messages', 'Warning Messages')) {
            $sheet = $xml.SelectSingleNode("//ss:Worksheet[@ss:Name='$name']", $ns)
            if ($null -eq $sheet) { continue }
            $rows = @($sheet.SelectNodes('.//ss:Row', $ns) | Select-Object -Skip 1 | ForEach-Object {
                @($_.SelectNodes('./ss:Cell/ss:Data', $ns) | ForEach-Object { $_.InnerText })
            })
            if ($name -eq 'Objects by Categories') { $categoryRows = $rows }
            elseif ($name -eq 'Error Messages') { $errorRows = $rows }
            else { $warningRows = $rows }
        }
        $objects.Add([pscustomobject]@{
            Report = $report.FullName.Substring($inputDir.Length + 1)
            LastWriteTime = $report.LastWriteTime.ToString('o')
            ValidXml = $true
            HasDetailedAssessment = $null -ne $summary
            WorkbookPresent = $null -ne $workbook
            Categories = $categoryRows
            Errors = $errorRows
            Warnings = $warningRows
        })
    } catch {
        $objects.Add([pscustomobject]@{
            Report = $report.FullName.Substring($inputDir.Length + 1)
            LastWriteTime = $report.LastWriteTime.ToString('o')
            ValidXml = $false
            HasDetailedAssessment = $false
            WorkbookPresent = $false
            Error = $_.Exception.Message
        })
    }
}

$output = Join-Path $artifactDir 'ssma-report-inventory.json'
$json = ConvertTo-Json -InputObject @($objects) -Depth 5
$json | Set-Content -LiteralPath $output -Encoding utf8
Get-Content -LiteralPath $output -Raw
