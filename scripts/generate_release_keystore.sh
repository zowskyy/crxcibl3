#!/usr/bin/env bash
# Generate a release signing keystore for Google Play Store exports.
# The keystore is gitignored — commit nothing from this step.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="${ROOT}/godot/release.keystore"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force]

Creates godot/release.keystore for Play Store release signing (2048-bit RSA, 25-year validity).

Environment (optional overrides):
  CRXCIBL3_KEYSTORE_ALIAS   Key alias (default: crxcibl3-release)
  CRXCIBL3_KEYSTORE_PASS    Store and key password (default: prompted)
  CRXCIBL3_KEYSTORE_DNAME   Distinguished name (default: CN=CRXCIBL3 Release,O=Zowskyy,C=US)

After generation:
  1. Back up the keystore and passwords offline — loss blocks Play Store updates.
  2. For local exports, set:
       export CRXCIBL3_KEYSTORE_PATH="$KEYSTORE"
       export CRXCIBL3_KEYSTORE_USER="<alias>"
       export CRXCIBL3_KEYSTORE_PASS="<password>"
  3. Or run: scripts/export_android_play_store.sh (uses godot/release.keystore when present)

For CI, store the keystore as ANDROID_KEYSTORE_BASE64 plus ANDROID_KEYSTORE_PASSWORD and
ANDROID_KEY_ALIAS GitHub Actions secrets, then trigger the android-play-store workflow.
EOF
}

FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
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

if [[ -f "$KEYSTORE" && "$FORCE" -ne 1 ]]; then
  echo "Keystore already exists: $KEYSTORE" >&2
  echo "Re-run with --force to overwrite (you will lose the old signing key)." >&2
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found — install a JDK (Java 17+ recommended)." >&2
  exit 1
fi

ALIAS="${CRXCIBL3_KEYSTORE_ALIAS:-crxcibl3-release}"
DNAME="${CRXCIBL3_KEYSTORE_DNAME:-CN=CRXCIBL3 Release,O=Zowskyy,C=US}"

if [[ -z "${CRXCIBL3_KEYSTORE_PASS:-}" ]]; then
  read -r -s -p "Keystore password (store + key): " CRXCIBL3_KEYSTORE_PASS
  echo
  if [[ -z "$CRXCIBL3_KEYSTORE_PASS" ]]; then
    echo "Password cannot be empty." >&2
    exit 1
  fi
fi

mkdir -p "$(dirname "$KEYSTORE")"
keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storepass "$CRXCIBL3_KEYSTORE_PASS" \
  -keypass "$CRXCIBL3_KEYSTORE_PASS" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 9125 \
  -dname "$DNAME"

echo
echo "Created release keystore: $KEYSTORE"
echo "  alias: $ALIAS"
echo
echo "Next steps:"
echo "  export CRXCIBL3_KEYSTORE_PATH=\"$KEYSTORE\""
echo "  export CRXCIBL3_KEYSTORE_USER=\"$ALIAS\""
echo "  export CRXCIBL3_KEYSTORE_PASS=\"<your password>\""
echo "  scripts/export_android_play_store.sh"
echo
echo "Back up the keystore and credentials securely before uploading to Play Console."
