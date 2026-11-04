#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/make_art.py
python3 tools/make_ui_art.py
python3 tools/make_environment.py
python3 tools/make_frontier_art.py
