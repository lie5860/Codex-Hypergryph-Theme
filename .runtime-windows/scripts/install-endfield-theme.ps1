[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
$portExplicit = $PSBoundParameters.ContainsKey('Port')
$root = Split-Path -Parent $PSScriptRoot
$install = Join-Path $PSScriptRoot 'install-dream-skin.ps1'
$start = Join-Path $PSScriptRoot 'start-dream-skin.ps1'

$installArguments = @{ NoShortcuts = $true }
if ($portExplicit) { $installArguments.Port = $Port }
& $install @installArguments

. (Join-Path $PSScriptRoot 'common-windows.ps1')
. (Join-Path $PSScriptRoot 'theme-windows.ps1')
$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'
$themePath = Join-Path $root 'assets\theme.json'
$imagePath = Join-Path $root 'assets\dream-reference.jpg'
$theme = (Read-DreamSkinUtf8File -Path $themePath) | ConvertFrom-Json -ErrorAction Stop
$active = Set-DreamSkinActiveTheme -ImagePath $imagePath -Theme $theme -StateRoot $stateRoot
if ("$($active.Theme.id)" -cne 'preset-endfield-frontier') {
  throw 'The Endfield theme could not be activated.'
}

$startArguments = @{ PromptRestart = $true }
if ($portExplicit) { $startArguments.Port = $Port }
& $start @startArguments
