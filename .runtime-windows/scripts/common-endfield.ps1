$script:EndfieldExpectedUpstreamCommit = 'a1c48b3a84cc64532196e624fdf33ee1277cb018'

function Get-EndfieldProjectPaths {
  $runtimeRoot = Split-Path -Parent $PSScriptRoot
  $repositoryRoot = Split-Path -Parent $runtimeRoot
  $vendorRoot = Join-Path $repositoryRoot 'vendor\Codex-Dream-Skin'
  return [pscustomobject]@{
    Repository = $repositoryRoot
    Runtime = $runtimeRoot
    Assets = Join-Path $runtimeRoot 'assets'
    Vendor = $vendorRoot
    VendorWindows = Join-Path $vendorRoot 'windows'
    UpstreamCommit = Join-Path $vendorRoot 'UPSTREAM_COMMIT'
  }
}

function Test-EndfieldPathWithin {
  param([string]$Path, [string]$Root)
  if (-not $Path -or -not $Root) { return $false }
  try {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $prefix = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    return $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
  } catch {
    return $false
  }
}

function Assert-EndfieldVendor {
  $paths = Get-EndfieldProjectPaths
  if (-not (Test-Path -LiteralPath $paths.UpstreamCommit -PathType Leaf)) {
    throw "The pinned upstream commit marker is missing: $($paths.UpstreamCommit)"
  }
  $commit = ([System.IO.File]::ReadAllText($paths.UpstreamCommit)).Trim()
  if ($commit -cne $script:EndfieldExpectedUpstreamCommit) {
    throw "Unexpected Codex Dream Skin revision: $commit"
  }
  $required = @(
    'scripts\common-windows.ps1',
    'scripts\config-utf8.ps1',
    'scripts\image-metadata.mjs',
    'scripts\injector.mjs',
    'scripts\install-dream-skin.ps1',
    'scripts\restore-dream-skin.ps1',
    'scripts\start-dream-skin.ps1',
    'scripts\theme-windows.ps1',
    'scripts\tray-dream-skin.ps1',
    'scripts\verify-dream-skin.ps1'
  )
  foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $paths.VendorWindows $relative) -PathType Leaf)) {
      throw "The vendored Codex Dream Skin engine is incomplete: $relative"
    }
  }
  $forbiddenPatterns = @(
    ('-WindowStyle' + '\s+Hidden'),
    ('CreateNoWindow' + '\s*=\s*\$?true'),
    ('SW_' + 'HIDE'),
    ('CREATE_' + 'NO_WINDOW')
  )
  $forbidden = @(Get-ChildItem -LiteralPath (Join-Path $paths.VendorWindows 'scripts') -Filter '*.ps1' -File |
    Select-String -Pattern $forbiddenPatterns)
  if ($forbidden.Count -gt 0) {
    throw "The vendored engine contains a forbidden hidden-process launch: $($forbidden[0].Path):$($forbidden[0].LineNumber)"
  }
  return $paths
}

function Invoke-EndfieldNative {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @()
  )
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $nativeOutput = @(& $FilePath @ArgumentList 2>$null)
    return [pscustomobject]@{
      Output = @($nativeOutput | ForEach-Object { "$_" })
      ExitCode = $LASTEXITCODE
    }
  } finally {
    $ErrorActionPreference = $previousPreference
  }
}

function Add-EndfieldNodeCandidate {
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Candidates,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$Seen,
    [AllowNull()][string]$Path
  )
  if (-not $Path) { return }
  try { $fullPath = [System.IO.Path]::GetFullPath($Path) } catch { return }
  if ($Seen.Add($fullPath)) { $Candidates.Add($fullPath) }
}

function Get-EndfieldNodeCandidates {
  $candidates = [System.Collections.Generic.List[string]]::new()
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

  Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen -Path $env:CODEX_DREAM_SKIN_NODE
  foreach ($commandName in @('node.exe', 'node')) {
    foreach ($command in @(Get-Command $commandName -All -ErrorAction SilentlyContinue)) {
      Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen -Path $command.Source
    }
  }
  foreach ($path in @(
    (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
    $(if (${env:ProgramFiles(x86)}) { Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe' }),
    (Join-Path $env:LOCALAPPDATA 'Programs\nodejs\node.exe'),
    $(if ($env:NVM_SYMLINK) { Join-Path $env:NVM_SYMLINK 'node.exe' }),
    $(if ($env:VOLTA_HOME) { Join-Path $env:VOLTA_HOME 'bin\node.exe' }),
    (Join-Path $HOME '.volta\bin\node.exe'),
    (Join-Path $HOME 'scoop\apps\nodejs\current\node.exe'),
    (Join-Path $HOME 'scoop\apps\nodejs-lts\current\node.exe')
  )) {
    Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen -Path $path
  }

  $fnmRoots = @($env:FNM_DIR, (Join-Path $env:APPDATA 'fnm'), (Join-Path $env:LOCALAPPDATA 'fnm')) |
    Where-Object { $_ }
  foreach ($fnmRoot in $fnmRoots) {
    foreach ($directory in @(Get-ChildItem -LiteralPath (Join-Path $fnmRoot 'node-versions') -Directory `
      -ErrorAction SilentlyContinue | Sort-Object { try { [version]$_.Name.TrimStart('v') } catch { [version]'0.0' } } -Descending)) {
      Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen `
        -Path (Join-Path $directory.FullName 'installation\node.exe')
    }
  }

  $nvmRoots = @($env:NVM_HOME, (Join-Path $env:APPDATA 'nvm'), (Join-Path $env:LOCALAPPDATA 'nvm')) |
    Where-Object { $_ }
  foreach ($nvmRoot in $nvmRoots) {
    foreach ($directory in @(Get-ChildItem -LiteralPath $nvmRoot -Directory -ErrorAction SilentlyContinue |
      Sort-Object { try { [version]$_.Name.TrimStart('v') } catch { [version]'0.0' } } -Descending)) {
      Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen -Path (Join-Path $directory.FullName 'node.exe')
    }
  }

  $voltaTools = if ($env:VOLTA_HOME) { Join-Path $env:VOLTA_HOME 'tools\image\node' } else {
    Join-Path $HOME '.volta\tools\image\node'
  }
  foreach ($directory in @(Get-ChildItem -LiteralPath $voltaTools -Directory -ErrorAction SilentlyContinue |
    Sort-Object { try { [version]$_.Name.TrimStart('v') } catch { [version]'0.0' } } -Descending)) {
    Add-EndfieldNodeCandidate -Candidates $candidates -Seen $seen -Path (Join-Path $directory.FullName 'node.exe')
  }
  return $candidates.ToArray()
}

function Get-EndfieldNodeRuntime {
  param([int]$MinimumMajor = 22)
  $detected = [System.Collections.Generic.List[string]]::new()
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($candidate in @(Get-EndfieldNodeCandidates)) {
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
    try {
      $versionProbe = Invoke-EndfieldNative -FilePath $candidate -ArgumentList @('-p', 'process.versions.node')
      $version = ($versionProbe.Output -join '').Trim()
      if ($versionProbe.ExitCode -ne 0 -or -not $version) { continue }
      $pathProbe = Invoke-EndfieldNative -FilePath $candidate -ArgumentList @('-p', 'process.execPath')
      $runtimePath = ($pathProbe.Output -join '').Trim()
      if ($pathProbe.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) { continue }
      $runtimePath = [System.IO.Path]::GetFullPath($runtimePath)
      if (-not $seen.Add($runtimePath)) { continue }
      $major = 0
      if (-not [int]::TryParse(($version -split '\.')[0], [ref]$major)) { continue }
      $detected.Add("$version at $runtimePath")
      if ($major -ge $MinimumMajor) {
        return [pscustomobject]@{ Path = $runtimePath; Version = $version; Major = $major }
      }
    } catch {}
  }
  if ($detected.Count -gt 0) {
    throw "Node.js $MinimumMajor or newer is required. Detected: $($detected -join '; ')"
  }
  throw "Node.js $MinimumMajor or newer was not found in PATH, fnm, nvm-windows, Volta, or common install locations."
}

function Set-EndfieldNodeEnvironment {
  $node = Get-EndfieldNodeRuntime
  $nodeDirectory = Split-Path -Parent $node.Path
  $remaining = @($env:PATH -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ine $nodeDirectory.TrimEnd('\') })
  $env:PATH = (@($nodeDirectory) + $remaining) -join ';'
  $env:CODEX_DREAM_SKIN_NODE = $node.Path
  return $node
}

function Remove-EndfieldRuntimeStage {
  param([Parameter(Mandatory = $true)][string]$Path)
  $stageParent = Join-Path ([System.IO.Path]::GetTempPath()) 'CodexHypergryphTheme'
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-EndfieldPathWithin -Path $fullPath -Root $stageParent)) {
    throw "Refusing to remove a staging path outside $stageParent"
  }
  if (Test-Path -LiteralPath $fullPath) {
    Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction Stop
  }
}

function New-EndfieldRuntimeStage {
  $paths = Assert-EndfieldVendor
  $stageParent = Join-Path ([System.IO.Path]::GetTempPath()) 'CodexHypergryphTheme'
  New-Item -ItemType Directory -Force -Path $stageParent | Out-Null
  $stageRoot = Join-Path $stageParent ([guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $stageRoot | Out-Null
  try {
    Copy-Item -LiteralPath (Join-Path $paths.VendorWindows 'scripts') -Destination $stageRoot `
      -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath (Join-Path $paths.VendorWindows 'tests') -PathType Container) {
      Copy-Item -LiteralPath (Join-Path $paths.VendorWindows 'tests') -Destination $stageRoot `
        -Recurse -Force -ErrorAction Stop
    }
    $stageAssets = Join-Path $stageRoot 'assets'
    New-Item -ItemType Directory -Path $stageAssets | Out-Null
    foreach ($asset in @('dream-reference.jpg', 'dream-skin.css', 'renderer-inject.js', 'theme.json')) {
      $source = Join-Path $paths.Assets $asset
      if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "The Endfield resource pack is incomplete: $asset"
      }
      Copy-Item -LiteralPath $source -Destination (Join-Path $stageAssets $asset) -Force
    }
    return [pscustomobject]@{
      Root = $stageRoot
      Assets = $stageAssets
      Scripts = Join-Path $stageRoot 'scripts'
      Install = Join-Path $stageRoot 'scripts\install-dream-skin.ps1'
      Tests = Join-Path $stageRoot 'tests\run-tests.ps1'
    }
  } catch {
    Remove-EndfieldRuntimeStage -Path $stageRoot
    throw
  }
}

function Get-EndfieldInstalledEngine {
  $root = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\engine'
  $scripts = Join-Path $root 'scripts'
  return [pscustomobject]@{
    Root = $root
    Assets = Join-Path $root 'assets'
    Scripts = $scripts
    Common = Join-Path $scripts 'common-windows.ps1'
    Theme = Join-Path $scripts 'theme-windows.ps1'
    Injector = Join-Path $scripts 'injector.mjs'
    Start = Join-Path $scripts 'start-dream-skin.ps1'
    Restore = Join-Path $scripts 'restore-dream-skin.ps1'
  }
}

function Assert-EndfieldInstalledEngine {
  $engine = Get-EndfieldInstalledEngine
  foreach ($path in @($engine.Common, $engine.Theme, $engine.Injector, $engine.Start, $engine.Restore)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw 'The Windows theme is not installed. Run the Endfield installer first.'
    }
  }
  return $engine
}

function Get-EndfieldProfilePath {
  return Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\codex-profile'
}

function Set-EndfieldActiveTheme {
  param([Parameter(Mandatory = $true)][object]$Engine)
  $paths = Get-EndfieldProjectPaths
  . $Engine.Common
  . $Engine.Theme
  $themePath = Join-Path $paths.Assets 'theme.json'
  $imagePath = Join-Path $paths.Assets 'dream-reference.jpg'
  $theme = (Read-DreamSkinUtf8File -Path $themePath) | ConvertFrom-Json -ErrorAction Stop
  $active = Set-DreamSkinActiveTheme -ImagePath $imagePath -Theme $theme
  if ("$($active.Theme.id)" -cne 'preset-endfield-frontier') {
    throw 'The Endfield resource pack could not be activated.'
  }
  return $active
}
