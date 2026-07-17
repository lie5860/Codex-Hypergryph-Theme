#!/bin/bash

set -euo pipefail
INSTALLED="$HOME/.codex/codex-dream-skin-studio/scripts/start-dream-skin-macos.sh"
[ -x "$INSTALLED" ] || { printf '请先安装终末地主题。\n' >&2; exit 1; }
exec "$INSTALLED" --prompt-restart
