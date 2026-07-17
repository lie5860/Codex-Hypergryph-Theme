[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common-endfield.ps1')

$engine = Assert-EndfieldInstalledEngine
$arguments = @{ RestoreBaseTheme = $true; PromptRestart = $true }
if ($PSBoundParameters.ContainsKey('Port')) { $arguments.Port = $Port }
& $engine.Restore @arguments
