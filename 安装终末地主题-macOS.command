#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
ENGINE="$ROOT/.runtime-macos"

"$ENGINE/scripts/install-dream-skin-macos.sh" --no-launchers --no-launch
"$HOME/.codex/codex-dream-skin-studio/scripts/switch-theme-macos.sh" \
  --id preset-endfield-frontier --no-apply
exec "$HOME/.codex/codex-dream-skin-studio/scripts/start-dream-skin-macos.sh" \
  --prompt-restart
