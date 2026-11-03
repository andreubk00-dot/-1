#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f build/web/index.html ]]; then
 echo 'Сначала выполните ./tools/build-web.sh' >&2
 exit 1
fi
exec python3 -m http.server "${PORT:-8765}" --bind 127.0.0.1 --directory build/web
