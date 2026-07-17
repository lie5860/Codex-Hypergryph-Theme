[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
$arguments = @{ PromptRestart = $true }
if ($PSBoundParameters.ContainsKey('Port')) { $arguments.Port = $Port }
& (Join-Path $PSScriptRoot 'start-dream-skin.ps1') @arguments
