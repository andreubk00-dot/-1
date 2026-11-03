#!/usr/bin/env bash
# Publishes the tested browser archive to the repository's existing gh-pages branch.
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_PAGES_REMOTE=$(git remote get-url origin)
TASK_PAGES_ROOT=$(mktemp -d /tmp/quiet-valley-publish.XXXXXX)
trap 'rm -rf "$TASK_PAGES_ROOT"' EXIT
git clone --single-branch --branch gh-pages "$TASK_PAGES_REMOTE" "$TASK_PAGES_ROOT/site"
python3 - "$TASK_PAGES_ROOT/site" <<'PY'
import json,sys
from pathlib import Path
from zipfile import ZipFile
root=Path(sys.argv[1]);old=None
if (root/'release.json').exists():old=json.loads((root/'release.json').read_text())['revision']
with ZipFile('dist/quiet-valley-web.zip') as z:
    assert z.testzip() is None
    current=json.loads(z.read('release.json'))['revision']
    for name in z.namelist():
        assert '/' not in name and '\\' not in name,name
        if not name.endswith('.import'):(root/name).write_bytes(z.read(name))
# Retain the preceding content-addressed release for clients with cached HTML.
for p in root.iterdir():
    if p.name.startswith(('game-','platform-')) and p.is_file():
        if not any(rev and p.name.startswith(('game-'+rev+'.','platform-'+rev+'.')) for rev in [current,old]):p.unlink()
(root/'.nojekyll').write_text('')
PY
git -C "$TASK_PAGES_ROOT/site" add .
if git -C "$TASK_PAGES_ROOT/site" diff --cached --quiet; then
 echo 'This exact release is already published.'
 exit 0
fi
git -C "$TASK_PAGES_ROOT/site" -c user.name=Codex -c user.email=codex@users.noreply.github.com commit -m 'Update Quiet Valley browser release'
git -C "$TASK_PAGES_ROOT/site" push origin gh-pages
