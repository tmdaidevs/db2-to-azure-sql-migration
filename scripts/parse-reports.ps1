[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$inputDir = Join-Path $Root 'input'
$artifactDir = Join-Path $Root 'migration-artifacts'
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$records = [System.Collections.Generic.List[object]]::new()
foreach ($report in @(Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter 'report.xml')) {
    try {
        [xml]$xml = Get-Content -LiteralPath $report.FullName -Raw
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace('ss','urn:schemas-microsoft-com:office:spreadsheet')
        $sheet = $xml.SelectSingleNode('//ss:Worksheet[@ss:Name="Detailed Assessment"]',$ns)
        if ($sheet) {
            $header = @($sheet.SelectNodes('.//ss:Row',$ns) | Select-Object -First 1 | ForEach-Object {$_.SelectNodes('./ss:Cell/ss:Data',$ns) | ForEach-Object {$_.InnerText}})
            foreach ($row in @($sheet.SelectNodes('.//ss:Row',$ns) | Select-Object -Skip 1)) {
                $values = @($row.SelectNodes('./ss:Cell/ss:Data',$ns) | ForEach-Object {$_.InnerText})
                if ($values.Count -ge 3 -and $values[0].Trim()) {
                    $item = [ordered]@{}
                    for($i=0;$i -lt $header.Count -and $i -lt $values.Count;$i++){ $item[$header[$i]]=$values[$i] }
                    $item.Report = $report.FullName.Substring($inputDir.Length+1)
                    $item.Status = if ([double]::TryParse($values[1],[ref]$null)) {'assessed'} else {'unknown'}
                    $records.Add([pscustomobject]$item)
                }
            }
        }
    } catch {
        $records.Add([pscustomobject]@{Report=$report.FullName.Substring($inputDir.Length+1); Status='invalid-report'; Error=$_.Exception.Message})
    }
}
foreach ($html in @(Get-ChildItem -LiteralPath $inputDir -Recurse -File -Filter 'messages.html')) {
    $text = Get-Content -LiteralPath $html.FullName -Raw
    foreach ($match in [regex]::Matches($text,'(?is)<span>(?<code>DB\d+SS\d+|0000)</span>.*?<span[^>]*>[^<]*</span>.*?<a[^>]*class="node-message[^>]*>\s*(?<object>[^<]+)')) {
        $records.Add([pscustomobject]@{
            Report = $html.FullName.Substring($inputDir.Length+1)
            Status = 'diagnostic'
            Code = $match.Groups['code'].Value
            Object = [System.Net.WebUtility]::HtmlDecode(($match.Groups['object'].Value -replace '\s+',' ').Trim())
        })
    }
}
$output = Join-Path $artifactDir 'parsed-ssma-reports.json'
$json = ConvertTo-Json -InputObject @($records) -Depth 12
$json | Set-Content -LiteralPath $output -Encoding utf8
Get-Content -LiteralPath $output -Raw
