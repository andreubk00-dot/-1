#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Keep runtime state outside the checkout in managed environments.
if [[ "$PWD" == /workspace/* ]]; then
 export XDG_DATA_HOME=/workspace/.runtime/valley/data
 export XDG_CONFIG_HOME=/workspace/.runtime/valley/config
 export XDG_CACHE_HOME=/workspace/.runtime/valley/cache
 mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
fi
exec godot --path . "$@"
