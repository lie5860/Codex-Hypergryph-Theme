[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common-endfield.ps1')

if ($PSVersionTable.PSVersion -lt [version]'5.1') {
  throw "Windows PowerShell 5.1 or newer is required; found $($PSVersionTable.PSVersion)."
}
Write-Host "[1/6] Windows PowerShell $($PSVersionTable.PSVersion)"

$null = Assert-EndfieldVendor
Write-Host "[2/6] Codex Dream Skin $script:EndfieldExpectedUpstreamCommit"

$node = Set-EndfieldNodeEnvironment
Write-Host "[3/6] Node.js $($node.Version): $($node.Path)"

$stage = New-EndfieldRuntimeStage
try {
  . (Join-Path $stage.Scripts 'common-windows.ps1')
  . (Join-Path $stage.Scripts 'theme-windows.ps1')
  Assert-DreamSkinPort -Port $Port
  $installs = @(Get-DreamSkinRegisteredCodexInstalls)
  if ($installs.Count -eq 0) {
    throw 'The official OpenAI.Codex Store package is not installed or its identity cannot be validated.'
  }
  $codex = $installs[0]
  Write-Host "[4/6] Codex $($codex.Version): $($codex.Executable)"

  $theme = Read-DreamSkinTheme -ThemeDirectory $stage.Assets
  if ("$($theme.Theme.id)" -cne 'preset-endfield-frontier') {
    throw "Unexpected theme ID in $($stage.Assets)"
  }
  Write-Host "[5/6] Endfield resources are valid: $($theme.Theme.name)"

  $injector = Join-Path $stage.Scripts 'injector.mjs'
  & $node.Path $injector --self-test
  if ($LASTEXITCODE -ne 0) { throw 'The injector self-test failed.' }
  & $node.Path $injector --check-payload --theme-dir $stage.Assets
  if ($LASTEXITCODE -ne 0) { throw 'The Endfield payload check failed.' }
  Write-Host '[6/6] Upstream injector accepted the Endfield payload.'

  $listeners = @(Get-DreamSkinPortListeners -Port $Port)
  if ($listeners.Count -gt 0) {
    $identity = Get-DreamSkinVerifiedCdpIdentity -Port $Port -Codex $codex
    if ($null -ne $identity) {
      Write-Host "Port $Port already belongs to a verified Codex theme session."
    } else {
      Write-Warning "Port $Port is occupied by another process. Startup will automatically choose a nearby free port."
    }
  } else {
    Write-Host "Port $Port is available."
  }
  Write-Host "Dedicated theme profile: $(Get-EndfieldProfilePath)"
  if (@(Get-DreamSkinCodexProcesses -Codex $codex).Count -gt 0) {
    Write-Host 'Codex is currently open. The installer will ask before restarting it.'
  }
  Write-Host 'Windows environment check passed.'
} finally {
  Remove-EndfieldRuntimeStage -Path $stage.Root
}
