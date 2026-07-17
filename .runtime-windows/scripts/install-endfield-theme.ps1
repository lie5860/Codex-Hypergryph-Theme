[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
$portExplicit = $PSBoundParameters.ContainsKey('Port')
. (Join-Path $PSScriptRoot 'common-endfield.ps1')

$node = Set-EndfieldNodeEnvironment
Write-Host "[Codex Hypergryph Theme] Using Node.js $($node.Version) from $($node.Path)"
$stage = New-EndfieldRuntimeStage
try {
  $installArguments = @{ NoShortcuts = $true }
  if ($portExplicit) { $installArguments.Port = $Port }
  & $stage.Install @installArguments

  $engine = Assert-EndfieldInstalledEngine
  $null = Set-EndfieldActiveTheme -Engine $engine
  $startArguments = @{
    PromptRestart = $true
    ProfilePath = (Get-EndfieldProfilePath)
  }
  if ($portExplicit) { $startArguments.Port = $Port }
  & $engine.Start @startArguments
} finally {
  Remove-EndfieldRuntimeStage -Path $stage.Root
}
