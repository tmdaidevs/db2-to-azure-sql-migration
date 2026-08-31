[CmdletBinding()]
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$dir=Join-Path $Root 'migration-artifacts\db2-extraction';New-Item -ItemType Directory -Force $dir|Out-Null
$queries=@{
  'tables.sql'='SELECT TABSCHEMA, TABNAME, COLCOUNT FROM SYSCAT.TABLES WHERE TYPE = ''T'''
  'routines.sql'='SELECT ROUTINESCHEMA, ROUTINENAME, ROUTINETYPE FROM SYSCAT.ROUTINES'
  'types.sql'='SELECT TYPESCHEMA, TYPENAME, TYPENAME FROM SYSCAT.DATATYPES'
}
foreach($item in $queries.GetEnumerator()){
  $file=Join-Path $dir $item.Key;$item.Value|Set-Content $file -Encoding utf8
  & (Join-Path $PSScriptRoot 'invoke-db2.ps1') -Root $Root -QueryFile $file -WhatIf | Out-File (Join-Path $dir "$($item.Key).plan.json") -Encoding utf8
}
[pscustomobject]@{Status='planned';Queries=@($queries.Keys);Note='Run without -WhatIf only after chat authorization and provider validation.'}|ConvertTo-Json

