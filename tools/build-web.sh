#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build dist
./tools/run.sh --headless --editor --import --quit
./tools/test.sh
# Content-addressed asset names prevent old HTML from loading a new incompatible PCK.
TASK_WEB_REVISION=$(python3 - <<'PY'
import hashlib
from pathlib import Path
h=hashlib.sha256()
paths=[Path('project.godot'),Path('export_presets.cfg')]
for folder in ['game','art','web']:
    paths.extend(p for p in Path(folder).rglob('*') if p.is_file() and p.suffix not in ['.import','.uid','.md'])
for p in sorted(set(paths)):
    h.update(str(p).encode());h.update(p.read_bytes())
print(h.hexdigest()[:12])
PY
)
TASK_WEB_STAGE=$(mktemp -d /tmp/quiet-valley-web.XXXXXX)
trap 'rm -rf "$TASK_WEB_STAGE"' EXIT
./tools/run.sh --headless --export-release Web "$TASK_WEB_STAGE/game-$TASK_WEB_REVISION.html"
cp web/platform.js "$TASK_WEB_STAGE/platform-$TASK_WEB_REVISION.js"
cp licenses/Godot-*.txt "$TASK_WEB_STAGE/"
cp art/FONT-LICENSE.txt "$TASK_WEB_STAGE/"
python3 - "$TASK_WEB_STAGE" "$TASK_WEB_REVISION" <<'PY'
import json,shutil,sys
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
stage=Path(sys.argv[1]);revision=sys.argv[2];base='game-'+revision
html=(stage/(base+'.html')).read_text().replace('src="platform.js"','src="platform-'+revision+'.js"')
assert '$GODOT_' not in html
(stage/'index.html').write_text(html)
(stage/(base+'.html')).unlink()
assert (stage/(base+'.wasm')).stat().st_size>1000000
assert (stage/(base+'.pck')).is_file()
(stage/'release.json').write_text(json.dumps({'version':'0.2.0','revision':revision},indent=2))
root=Path('build/web')
if root.exists():shutil.rmtree(root)
shutil.copytree(stage,root)
with ZipFile('dist/quiet-valley-web.zip.tmp','w',ZIP_DEFLATED) as z:
    for p in sorted(root.iterdir()):
        if p.is_file() and not p.name.endswith('.import'):z.write(p,p.name)
Path('dist/quiet-valley-web.zip.tmp').replace('dist/quiet-valley-web.zip')
print('Created dist/quiet-valley-web.zip; revision '+revision)
PY
