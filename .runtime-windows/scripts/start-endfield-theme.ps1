[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common-endfield.ps1')

$null = Set-EndfieldNodeEnvironment
$engine = Assert-EndfieldInstalledEngine
$arguments = @{
  PromptRestart = $true
  ProfilePath = (Get-EndfieldProfilePath)
}
if ($PSBoundParameters.ContainsKey('Port')) { $arguments.Port = $Port }
& $engine.Start @arguments
