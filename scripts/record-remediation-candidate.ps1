[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Record,
    [Parameter(Mandatory)][string]$CandidateFile,
    [Parameter(Mandatory)][ValidateSet('generated','compiled','rejected','accepted')][string]$Status,
    [Parameter()][string]$CompileError = '',
    [Parameter()][string]$Reviewer = ''
)
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $Record)){throw "Remediation record not found: $Record"}
if(-not(Test-Path -LiteralPath $CandidateFile)){throw "Candidate file not found: $CandidateFile"}
$item=Get-Content -LiteralPath $Record -Raw|ConvertFrom-Json
$candidate=[pscustomobject]@{file=$CandidateFile;status=$Status;compileError=$CompileError;reviewer=$Reviewer;recordedAt=(Get-Date).ToUniversalTime().ToString('o')}
$item.candidates=@($item.candidates)+$candidate
if($Status -eq 'accepted'){$item.acceptedCandidate=$CandidateFile;$item.status='accepted'}
elseif($Status -eq 'rejected'){$item.rejectedCandidates=@($item.rejectedCandidates)+$candidate}
$item|ConvertTo-Json -Depth 12|Set-Content -LiteralPath $Record -Encoding utf8
$item|ConvertTo-Json -Depth 12
