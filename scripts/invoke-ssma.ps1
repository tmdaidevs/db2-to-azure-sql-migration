[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SsmaConsole,
    [Parameter(Mandatory)]
    [string]$ScriptFile,
    [Parameter()]
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [Parameter()]
    [string[]]$Arguments = @()
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $SsmaConsole -PathType Leaf)) {
    throw "SSMA Console executable was not found: $SsmaConsole"
}
if (-not (Test-Path -LiteralPath $ScriptFile -PathType Leaf)) {
    throw "SSMA script file was not found: $ScriptFile"
}

$runId = Get-Date -Format 'yyyyMMddTHHmmssfffZ'
$runDir = Join-Path (Join-Path $Root 'migration-artifacts') "ssma-$runId"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$stdout = Join-Path $runDir 'stdout.log'
$stderr = Join-Path $runDir 'stderr.log'
$metadata = [pscustomobject]@{
    startedAt = (Get-Date).ToUniversalTime().ToString('o')
    executable = $SsmaConsole
    scriptFile = $ScriptFile
    arguments = $Arguments
}
$metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runDir 'invocation.json') -Encoding utf8

$process = Start-Process -FilePath $SsmaConsole -ArgumentList $Arguments -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$result = [pscustomobject]@{
    runDirectory = $runDir
    exitCode = $process.ExitCode
    stdout = $stdout
    stderr = $stderr
}
$result | ConvertTo-Json
if ($process.ExitCode -ne 0) {
    throw "SSMA Console failed with exit code $($process.ExitCode). See $runDir."
}

