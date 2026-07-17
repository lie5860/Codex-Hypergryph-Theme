[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$runtimeRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $runtimeRoot 'scripts'
. (Join-Path $scriptsRoot 'common-endfield.ps1')

$parseErrors = @()
foreach ($file in Get-ChildItem -LiteralPath $scriptsRoot -Filter '*.ps1' -File) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors) { $parseErrors += $errors }
}
if ($parseErrors.Count -gt 0) { throw ($parseErrors | Out-String) }

$forbiddenPatterns = @(
  ('-WindowStyle' + '\s+Hidden'),
  ('CreateNoWindow' + '\s*=\s*\$?true'),
  ('SW_' + 'HIDE'),
  ('CREATE_' + 'NO_WINDOW')
)
$forbidden = @(Get-ChildItem -LiteralPath (Get-EndfieldProjectPaths).Repository -Recurse -File |
  Where-Object { $_.Extension -in @('.ps1', '.cmd', '.mjs', '.js') } |
  Select-String -Pattern $forbiddenPatterns)
if ($forbidden.Count -gt 0) {
  throw "A hidden-process launch remains in $($forbidden[0].Path):$($forbidden[0].LineNumber)"
}

$node = Set-EndfieldNodeEnvironment
$stage = New-EndfieldRuntimeStage
try {
  & $node.Path --check (Join-Path $runtimeRoot 'assets\renderer-inject.js')
  if ($LASTEXITCODE -ne 0) { throw 'The Endfield renderer syntax check failed.' }
  & $node.Path (Join-Path $stage.Scripts 'injector.mjs') --self-test
  if ($LASTEXITCODE -ne 0) { throw 'The upstream injector self-test failed.' }
  & $node.Path (Join-Path $stage.Scripts 'injector.mjs') --check-payload --theme-dir $stage.Assets
  if ($LASTEXITCODE -ne 0) { throw 'The upstream injector rejected the Endfield payload.' }
  & $stage.Tests -EngineOnly
  & $node.Path (Join-Path $PSScriptRoot 'resource-pack.test.mjs')
  if ($LASTEXITCODE -ne 0) { throw 'The Endfield resource-pack test failed.' }
} finally {
  Remove-EndfieldRuntimeStage -Path $stage.Root
}

Write-Host 'PASS: Windows adapter, upstream engine, and Endfield resource tests.'
