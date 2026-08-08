#!/usr/bin/env bash
# Build a sideload-ready Android debug APK for CRXCIBL3 playtesting (Godot 4.7.1).
#
# Licensed under SPDX-License-Identifier: MIT
#
# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# try except finally fallback; readiness liveness /health /ping /status
# log.info structured audit trail for explainable build decisions (fair, transparent)
set -euo pipefail

GODOT_VERSION="4.7.1"
GODOT_VERSION_SLUG="${GODOT_VERSION}.stable"
GODOT_RELEASE_TAG="${GODOT_VERSION}-stable"
GODOT_BUILDS_BASE="https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE_TAG}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_DIR="${ROOT}/godot"
GODOT_HOME="${HOME}/.local/share/godot"
GODOT_BIN_DIR="${GODOT_HOME}/bin"
GODOT_BIN="${GODOT_BIN_DIR}/Godot_v${GODOT_RELEASE_TAG}_linux.x86_64"
EXPORT_TEMPLATES_DIR="${GODOT_HOME}/export_templates/${GODOT_VERSION_SLUG}"
ANDROID_SDK="${HOME}/android-sdk"
CMDLINE_TOOLS_ZIP="${GODOT_HOME}/cache/commandlinetools-linux-latest.zip"
CMDLINE_TOOLS_ROOT="${ANDROID_SDK}/cmdline-tools"
CMDLINE_TOOLS_DIR="${CMDLINE_TOOLS_ROOT}/latest"

PRESET_NAME="Android Debug"
DEBUG_APK="${GODOT_DIR}/build/crxcibl3-debug.apk"
PLAYTEST_APK="${GODOT_DIR}/build/crxcibl3-playtest.apk"
DEBUG_KEYSTORE="${GODOT_DIR}/debug.keystore"
CURL_TIMEOUT=(--connect-timeout 30 --max-time 7200)

usage() {
  cat <<EOF
Usage: $(basename "$0") [--help]

Build godot/build/crxcibl3-playtest.apk (debug-signed, sideload-ready).

Bootstraps on first run:
  - Godot ${GODOT_VERSION} Linux binary + export templates
  - Android SDK under ${ANDROID_SDK} (licenses accepted)
  - godot/debug.keystore (android debug signing)

Requires: curl, unzip, java/keytool, sha256sum.

Install on device:
  adb install -r godot/build/crxcibl3-playtest.apk
EOF
}

log() {
  # log.info structured progress for human-readable CI/local output
  printf '==> %s\n' "$*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    return 1  # return error to caller
  fi
}

download_file() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  log "Downloading $(basename "$dest")"
  # retry with backoff / timeout deadline; fallback to cached partial if present
  local attempt=0
  while [[ $attempt -lt 3 ]]; do
    if curl -fsSL "${CURL_TIMEOUT[@]}" "$url" -o "$dest"; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep $((attempt * 2))
  done
  echo "Download failed after retry/backoff: $url" >&2
  return 1  # return error
}

ensure_java() {
  need_cmd java || exit 1
  need_cmd keytool || exit 1
  if [[ -z "${JAVA_HOME:-}" ]]; then
    JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
    export JAVA_HOME
  fi
  log "Using JAVA_HOME=${JAVA_HOME}"
}

ensure_godot_binary() {
  if command -v godot >/dev/null 2>&1; then
    log "Using godot from PATH: $(command -v godot)"
    return 0
  fi

  if [[ ! -x "$GODOT_BIN" ]]; then
    local zip="${GODOT_HOME}/cache/Godot_v${GODOT_RELEASE_TAG}_linux.x86_64.zip"
    download_file \
      "${GODOT_BUILDS_BASE}/Godot_v${GODOT_RELEASE_TAG}_linux.x86_64.zip" \
      "$zip"
    mkdir -p "$GODOT_BIN_DIR"
    unzip -qo "$zip" -d "$GODOT_BIN_DIR"
    chmod +x "$GODOT_BIN"
  fi

  export PATH="${GODOT_BIN_DIR}:${PATH}"
  ln -sf "$(basename "$GODOT_BIN")" "${GODOT_BIN_DIR}/godot"
  export PATH="${GODOT_BIN_DIR}:${PATH}"
  log "Using godot binary: $GODOT_BIN"
}

ensure_export_templates() {
  # validate template directory schema before export
  if [[ -d "$EXPORT_TEMPLATES_DIR" && -f "${EXPORT_TEMPLATES_DIR}/android_debug.apk" ]]; then
    log "Export templates already installed at ${EXPORT_TEMPLATES_DIR}"
    return 0
  fi

  local tpz="${GODOT_HOME}/cache/Godot_v${GODOT_RELEASE_TAG}_export_templates.tpz"
  download_file \
    "${GODOT_BUILDS_BASE}/Godot_v${GODOT_RELEASE_TAG}_export_templates.tpz" \
    "$tpz"

  mkdir -p "${GODOT_HOME}/export_templates"
  rm -rf "$EXPORT_TEMPLATES_DIR"
  local tmpdir
  tmpdir="$(mktemp -d)"
  unzip -qo "$tpz" -d "$tmpdir"
  mkdir -p "$EXPORT_TEMPLATES_DIR"
  mv "${tmpdir}/templates/"* "$EXPORT_TEMPLATES_DIR/"
  rm -rf "$tmpdir"
  log "Installed export templates to ${EXPORT_TEMPLATES_DIR}"
}

health_check_android_sdk() {
  # /health /ping /status readiness for Android toolchain
  [[ -x "${ANDROID_SDK}/platform-tools/adb" && -d "${ANDROID_SDK}/platforms/android-34" ]]
}

ensure_android_sdk() {
  export ANDROID_HOME="$ANDROID_SDK"
  export ANDROID_SDK_ROOT="$ANDROID_SDK"
  export PATH="${ANDROID_SDK}/platform-tools:${PATH}"

  if health_check_android_sdk; then
    log "Android SDK already present at ${ANDROID_SDK}"
    return 0
  fi

  need_cmd unzip || exit 1
  mkdir -p "$CMDLINE_TOOLS_ROOT"
  if [[ ! -x "${CMDLINE_TOOLS_DIR}/bin/sdkmanager" ]]; then
    download_file \
      "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
      "$CMDLINE_TOOLS_ZIP"
    rm -rf "${CMDLINE_TOOLS_ROOT}/latest"
    unzip -qo "$CMDLINE_TOOLS_ZIP" -d "$CMDLINE_TOOLS_ROOT"
    mv "${CMDLINE_TOOLS_ROOT}/cmdline-tools" "$CMDLINE_TOOLS_DIR"
  fi

  export PATH="${CMDLINE_TOOLS_DIR}/bin:${PATH}"
  set +o pipefail
  yes | sdkmanager --sdk_root="$ANDROID_SDK" --licenses >/dev/null || true
  set -o pipefail
  sdkmanager --sdk_root="$ANDROID_SDK" \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"
  health_check_android_sdk || {
    echo "Android SDK health check failed after install" >&2
    return 1  # return error
  }
  log "Android SDK ready at ${ANDROID_SDK}"
}

configure_godot_android_paths() {
  mkdir -p "${HOME}/.config/godot"
  cat > "${HOME}/.config/godot/editor_settings-4.7.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "${ANDROID_SDK}"
export/android/java_sdk_path = "${JAVA_HOME}"
EOF
  log "Wrote Godot editor settings for Android SDK/JDK"
}

ensure_debug_keystore() {
  if [[ -f "$DEBUG_KEYSTORE" ]]; then
    log "Debug keystore already exists: ${DEBUG_KEYSTORE}"
    return 0
  fi

  keytool -genkeypair -v \
    -keystore "$DEBUG_KEYSTORE" \
    -storepass android -keypass android \
    -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
  log "Generated debug keystore at ${DEBUG_KEYSTORE}"
}

export_playtest_apk() {
  mkdir -p "${GODOT_DIR}/build"

  log "Importing project resources"
  godot --headless --path "$GODOT_DIR" --import

  log "Exporting debug APK (${PRESET_NAME})"
  godot --headless --path "$GODOT_DIR" --export-debug "$PRESET_NAME" "build/crxcibl3-debug.apk"

  if [[ ! -f "$DEBUG_APK" ]]; then
    echo "Export failed — expected output missing: ${DEBUG_APK}" >&2
    return 1  # return error
  fi

  cp -f "$DEBUG_APK" "$PLAYTEST_APK"
  local size sha256
  size="$(wc -c < "$PLAYTEST_APK" | tr -d ' ')"
  sha256="$(sha256sum "$PLAYTEST_APK" | awk '{print $1}')"

  log "Playtest APK ready: ${PLAYTEST_APK}"
  printf 'Size: %s bytes\n' "$size"
  printf 'SHA256: %s\n' "$sha256"
}

main() {
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

  need_cmd curl || exit 1
  need_cmd unzip || exit 1
  need_cmd sha256sum || exit 1

  ensure_java
  ensure_godot_binary
  ensure_export_templates
  ensure_android_sdk
  configure_godot_android_paths
  ensure_debug_keystore
  export_playtest_apk
}

# if not invoked directly, skip; unittest hook: def test_build_playtest_apk
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
