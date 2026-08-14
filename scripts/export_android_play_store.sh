#!/usr/bin/env bash
# Headless Google Play Store AAB export for CRXCIBL3 (Godot 4.7.1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="${ROOT}/godot"
PRESET_NAME="Android Play Store"
OUTPUT="${GODOT_DIR}/build/crxcibl3-release.aab"
DEFAULT_KEYSTORE="${GODOT_DIR}/release.keystore"
CREDENTIALS_FILE="${GODOT_DIR}/export_credentials.cfg"
PLAY_STORE_PRESET_INDEX=4

usage() {
  cat <<EOF
Usage: $(basename "$0")

Builds a signed release AAB via Godot export preset "${PRESET_NAME}".

Requires release keystore credentials via environment:
  CRXCIBL3_KEYSTORE_PATH   Path to .keystore / .jks (optional if ${DEFAULT_KEYSTORE} exists)
  CRXCIBL3_KEYSTORE_USER   Key alias
  CRXCIBL3_KEYSTORE_PASS   Store and key password

If CRXCIBL3_KEYSTORE_PATH is unset, uses ${DEFAULT_KEYSTORE} when present.

Requires Godot 4.7.1 with Android export templates and ANDROID_HOME / JAVA_HOME configured.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v godot >/dev/null 2>&1; then
  echo "godot not found on PATH — install Godot 4.7.1 with Android export support." >&2
  exit 1
fi

KEYSTORE_PATH="${CRXCIBL3_KEYSTORE_PATH:-}"
if [[ -z "$KEYSTORE_PATH" && -f "$DEFAULT_KEYSTORE" ]]; then
  KEYSTORE_PATH="$DEFAULT_KEYSTORE"
fi

if [[ -z "$KEYSTORE_PATH" || ! -f "$KEYSTORE_PATH" ]]; then
  echo "Release keystore not found." >&2
  echo "Set CRXCIBL3_KEYSTORE_PATH or run scripts/generate_release_keystore.sh" >&2
  exit 1
fi

if [[ -z "${CRXCIBL3_KEYSTORE_USER:-}" || -z "${CRXCIBL3_KEYSTORE_PASS:-}" ]]; then
  echo "CRXCIBL3_KEYSTORE_USER and CRXCIBL3_KEYSTORE_PASS must be set." >&2
  exit 1
fi

# Godot res:// keystore paths must live under the project tree.
PROJECT_KEYSTORE="${GODOT_DIR}/release.keystore"
if [[ "$(realpath "$KEYSTORE_PATH")" != "$(realpath "$PROJECT_KEYSTORE")" ]]; then
  cp "$KEYSTORE_PATH" "$PROJECT_KEYSTORE"
fi

cleanup() {
  if [[ "${WROTE_CREDENTIALS:-0}" -eq 1 && -f "$CREDENTIALS_FILE" ]]; then
    rm -f "$CREDENTIALS_FILE"
  fi
}
trap cleanup EXIT

WROTE_CREDENTIALS=0
if [[ ! -f "$CREDENTIALS_FILE" ]]; then
  cat > "$CREDENTIALS_FILE" <<EOF
[preset.${PLAY_STORE_PRESET_INDEX}]

keystore/release_user="${CRXCIBL3_KEYSTORE_USER}"
keystore/release_password="${CRXCIBL3_KEYSTORE_PASS}"
EOF
  WROTE_CREDENTIALS=1
fi

mkdir -p "${GODOT_DIR}/build"

godot --headless --path "$GODOT_DIR" --install-android-build-template

echo "Exporting ${PRESET_NAME} -> ${OUTPUT}"
godot --headless --path "$GODOT_DIR" --export-release "$PRESET_NAME" "build/crxcibl3-release.aab"

if [[ ! -f "$OUTPUT" ]]; then
  echo "Export failed — expected output missing: $OUTPUT" >&2
  exit 1
fi

SIZE="$(wc -c < "$OUTPUT" | tr -d ' ')"
echo "AAB ready: $OUTPUT (${SIZE} bytes)"
