# Codex Hypergryph Theme

非官方 Codex Desktop 工业科幻主题资源包。视觉灵感来自鹰角网络《明日方舟》与《明日方舟：终末地》的边境工程美术语言。

本仓库不再分发安装脚本、启动脚本、注入器或 vendored runtime。脚本、安装、启动、恢复和校验都以主仓库 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) 为准；本仓只提供可导入/可替换的主题资源。

<p align="center">
  <img src="./docs/images/preview-desktop.png" alt="Codex Hypergryph Theme 桌面布局预览" width="100%">
  <br>
  <sub>脱敏预览；项目名均为虚构占位。</sub>
</p>

## 资源

- `主题资源/background.jpg`：原创工业科幻背景图。
- `主题资源/theme.json`：主题元数据，包含名称、文案、外观、构图参数和 accent 色。

本主题资源不新增、不隐藏 Codex 新建任务页的原生建议按钮。新版 Codex 或不同账号状态下可能不显示 suggestion cards；这种情况下主题只会渲染背景、标题区域和输入框外观。

## 使用方式

1. 先按主仓库文档安装并运行 Codex Dream Skin。
2. 将本仓库的 `主题资源` 目录作为一个 saved theme/preset 目录使用，目录内只需要 `theme.json` 与 `background.jpg`。
   - macOS 已安装主题库：`~/Library/Application Support/CodexDreamSkinStudio/themes/preset-endfield-frontier/`
   - Windows 已安装主题库：`%LOCALAPPDATA%\CodexDreamSkin\themes\preset-endfield-frontier\`
3. 继续使用主仓库自带命令或菜单切换、启动、验证和恢复主题；例如 macOS 可用主仓库的 `switch-theme-macos.sh --id preset-endfield-frontier`。

## 复制即用

下面命令默认你已经在本仓库根目录中运行，也就是当前目录下能看到 `主题资源`。脚本全部来自主仓库；本仓只把 `theme.json` 与 `background.jpg` 放进主仓库支持的主题库。

### macOS

```bash
THEME_SOURCE="$(pwd)/主题资源"
UPSTREAM="$HOME/Codex-Dream-Skin"

if [ -d "$UPSTREAM/.git" ]; then
  git -C "$UPSTREAM" pull --ff-only
else
  git clone https://github.com/Fei-Away/Codex-Dream-Skin.git "$UPSTREAM"
fi

cd "$UPSTREAM/macos"
./scripts/install-dream-skin-macos.sh --no-launch

THEME_ID="preset-endfield-frontier"
THEME_DEST="$HOME/Library/Application Support/CodexDreamSkinStudio/themes/$THEME_ID"
mkdir -p "$THEME_DEST"
cp "$THEME_SOURCE/theme.json" "$THEME_SOURCE/background.jpg" "$THEME_DEST/"

~/.codex/codex-dream-skin-studio/scripts/switch-theme-macos.sh --id "$THEME_ID"
~/.codex/codex-dream-skin-studio/scripts/start-dream-skin-macos.sh
```

### Windows

在 PowerShell 中运行。`$ThemeRepo` 必须指向本仓库根目录，也就是里面能看到 `主题资源` 的目录：

```powershell
$ThemeRepo = (Get-Location).Path
$ThemeSource = Join-Path $ThemeRepo '主题资源'
if (-not (Test-Path -LiteralPath (Join-Path $ThemeSource 'theme.json')) -or
    -not (Test-Path -LiteralPath (Join-Path $ThemeSource 'background.jpg'))) {
  throw "Theme resources not found. Run this block from the Codex-Hypergryph-Theme repo root, or set `$ThemeRepo to that absolute path."
}

$Upstream = Join-Path $env:USERPROFILE 'Codex-Dream-Skin'

if (Test-Path -LiteralPath (Join-Path $Upstream '.git')) {
  git -C $Upstream pull --ff-only
} else {
  git clone https://github.com/Fei-Away/Codex-Dream-Skin.git $Upstream
}

Set-Location (Join-Path $Upstream 'windows')
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1

$ThemeId = 'preset-endfield-frontier'
$ThemeDest = Join-Path $env:LOCALAPPDATA "CodexDreamSkin\themes\$ThemeId"
New-Item -ItemType Directory -Force -Path $ThemeDest | Out-Null
Copy-Item -LiteralPath (Join-Path $ThemeSource 'theme.json'), (Join-Path $ThemeSource 'background.jpg') -Destination $ThemeDest -Force

. .\scripts\common-windows.ps1
. .\scripts\theme-windows.ps1
Use-DreamSkinSavedTheme -ThemeDirectory $ThemeDest | Out-Null

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-dream-skin.ps1 -PromptRestart
```

如果主仓库后续更新了主题 schema，以主仓库文档为准，只调整 `theme.json` 和图片资源，不在本仓维护脚本分支。

<details>
<summary>最小窗口预览</summary>

<p align="center">
  <img src="./docs/images/preview-compact.png" alt="480 × 600 最小窗口布局预览" width="360">
</p>

</details>

## 声明

本项目与 OpenAI、鹰角网络均无隶属、授权或背书关系。仓库未包含官方游戏 CG、角色立绘或商标图形；背景为本项目生成的原创工业科幻画面。详细说明见 [NOTICE.md](./NOTICE.md) 与 [ASSET-PROVENANCE.md](./ASSET-PROVENANCE.md)。

## License

原创背景与脱敏预览采用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。
