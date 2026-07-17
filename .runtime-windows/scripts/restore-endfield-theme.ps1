[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
$arguments = @{ RestoreBaseTheme = $true; PromptRestart = $true }
if ($PSBoundParameters.ContainsKey('Port')) { $arguments.Port = $Port }
& (Join-Path $PSScriptRoot 'restore-dream-skin.ps1') @arguments
