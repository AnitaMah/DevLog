#!/usr/bin/env bash
set -euo pipefail

# Builds a macOS .app and packages it into a .dmg for 42 Guides.
#
# Requires:
#   - macOS with Xcode command line tools
#   - flutter (with macos desktop support enabled)
#   - create-dmg (https://github.com/create-dmg/create-dmg) — install with:
#       brew install create-dmg
#
# This script does NOT code-sign or notarize the app. Unsigned builds will
# be blocked by Gatekeeper on other Macs unless the user right-clicks ->
# Open, or the app is signed with an Apple Developer ID and notarized.
# Signing/notarizing requires an Apple Developer account and can't be
# scripted without one, so it's left as a follow-up.
#
# Usage (from the repo root, on macOS):
#   ./packaging/macos/build_dmg.sh
#
# Output:
#   build/macos/42 Guides.dmg

APP_DISPLAY_NAME="42 Guides"
BUILT_APP="build/macos/Build/Products/Release/dev_log.app"
OUT_DIR="build/macos"
DMG_PATH="${OUT_DIR}/${APP_DISPLAY_NAME}.dmg"

echo "==> flutter build macos --release"
flutter build macos --release

if [ ! -d "$BUILT_APP" ]; then
  echo "error: expected app bundle at $BUILT_APP, got a different output path."
  echo "check the 'flutter build macos' output above and adjust BUILT_APP."
  exit 1
fi

if ! command -v create-dmg &> /dev/null; then
  echo "error: create-dmg not found on PATH."
  echo "install it with: brew install create-dmg"
  exit 1
fi

rm -f "$DMG_PATH"

echo "==> packaging dmg"
create-dmg \
  --volname "$APP_DISPLAY_NAME" \
  --app-drop-link 450 150 \
  "$DMG_PATH" \
  "$BUILT_APP" \
  || true
# create-dmg returns a non-zero exit code on some benign warnings (e.g. no
# Finder access in CI), so we don't let `set -e` kill the script here —
# instead check that the dmg actually got created.

if [ ! -f "$DMG_PATH" ]; then
  echo "error: dmg was not created, see create-dmg output above."
  exit 1
fi

echo "==> done: $DMG_PATH"
