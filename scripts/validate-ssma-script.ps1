[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScriptFile
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ScriptFile -PathType Leaf)) { throw "SSMA script not found: $ScriptFile" }
[xml]$script = Get-Content -LiteralPath $ScriptFile -Raw
if ($script.DocumentElement.Name -ne 'ssma-script-file') { throw 'SSMA script root must be ssma-script-file.' }
if ($null -eq $script.SelectSingleNode('/ssma-script-file/script-commands')) { throw 'SSMA script must contain script-commands.' }
$allowed = @('open-project','connect-source-database','connect-target-database','generate-assessment-report','convert-schema','synchronize-target','migrate-data','save-project','close-project','map-schema')
$commands = @($script.SelectSingleNode('/ssma-script-file/script-commands').ChildNodes | Where-Object {$_.NodeType -eq 'Element'})
$unknown = @($commands | Where-Object {$_.Name -notin $allowed})
if ($unknown.Count) { throw "Unsupported SSMA commands: $($unknown.Name -join ', ')" }
[pscustomobject]@{ Valid = $true; Commands = @($commands | ForEach-Object Name) } | ConvertTo-Json

