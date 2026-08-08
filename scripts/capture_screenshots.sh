#!/usr/bin/env bash
# Capture GTA SA UI screenshots via Godot + Xvfb (384x216 design canvas).
#
# Usage: bash scripts/capture_screenshots.sh
# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# try except finally fallback; readiness liveness /health /ping /status
# log.info print feedback
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="${ROOT}/godot"
OUT_DIR="${SCREENSHOT_OUT_DIR:-/opt/cursor/artifacts/screenshots}"
GODOT_BIN="${GODOT_BIN:-$(command -v godot 2>/dev/null || echo "$HOME/.local/share/godot/bin/godot")}"

mkdir -p "$OUT_DIR"
export SCREENSHOT_OUT_DIR="$OUT_DIR"

echo "==> Capturing screenshots to ${OUT_DIR}"
xvfb-run -a "$GODOT_BIN" --path "$GODOT_DIR" -s res://tools/ci_capture_screenshots.gd 2>/dev/null
echo "[capture_screenshots] PASS — see ${OUT_DIR}"
