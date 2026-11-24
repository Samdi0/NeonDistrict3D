#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p build
"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . --export-release "Windows Desktop" build/NeonDistrict3D.exe
mkdir -p build/web
"$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
echo "Exports created under build/"
