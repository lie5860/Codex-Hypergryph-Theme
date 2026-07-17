#!/bin/bash

set -euo pipefail
INSTALLED="$HOME/.codex/codex-dream-skin-studio/scripts/restore-dream-skin-macos.sh"
[ -x "$INSTALLED" ] || { printf '没有找到已安装的终末地主题。\n' >&2; exit 1; }
exec "$INSTALLED" --restore-base-theme --restart-codex
