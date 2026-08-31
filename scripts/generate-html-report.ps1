[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$artifact=Join-Path $Root 'migration-artifacts';New-Item -ItemType Directory -Force $artifact|Out-Null
$state=Join-Path $artifact 'migration-state.json'
$phase=if(Test-Path $state){(Get-Content $state -Raw|ConvertFrom-Json).phase}else{'NOT_STARTED'}
$manifest=Join-Path $artifact 'object-manifest.json'
$count=if(Test-Path $manifest){(Get-Content $manifest -Raw|ConvertFrom-Json).objectCount}else{0}
$html=@"
<!doctype html><html><head><meta charset="utf-8"><title>DB2 to Azure SQL Migration Report</title></head>
<body><h1>DB2 to Azure SQL Migration Report</h1>
<p><strong>Phase:</strong> $phase</p><p><strong>Discovered objects:</strong> $count</p>
<p>This report contains sanitized operational evidence. Review blockers and validation evidence before promotion.</p>
</body></html>
"@
$path=Join-Path $artifact 'migration-report.html';$html|Set-Content -LiteralPath $path -Encoding utf8;Write-Output $path
