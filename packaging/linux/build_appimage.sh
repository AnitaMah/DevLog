#!/usr/bin/env bash
set -euo pipefail

# Builds a Linux AppImage for 42 Guides.
#
# Requires:
#   - flutter (with linux desktop support enabled)
#   - appimagetool: https://github.com/AppImage/AppImageKit/releases
#
# Usage (from the repo root):
#   ./packaging/linux/build_appimage.sh
#
# Output:
#   build/linux/42Guides-x86_64.AppImage

APP_NAME="42Guides"
EXE_NAME="dev_log"
BUNDLE_DIR="build/linux/x64/release/bundle"
APPDIR="build/linux/${APP_NAME}.AppDir"
ICON="assets/icon/app_icon_256.png"

echo "==> flutter build linux --release"
flutter build linux --release

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "error: expected bundle at $BUNDLE_DIR, got a different output path."
  echo "check the 'flutter build linux' output above and adjust BUNDLE_DIR."
  exit 1
fi

echo "==> assembling AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE_DIR"/. "$APPDIR/usr/bin/"

cat > "$APPDIR/usr/share/applications/${APP_NAME}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=42 Guides
Exec=${EXE_NAME}
Icon=${APP_NAME}
Categories=Utility;Education;
EOF

cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
ln -sf "usr/share/applications/${APP_NAME}.desktop" "$APPDIR/${APP_NAME}.desktop"
ln -sf "usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png" "$APPDIR/${APP_NAME}.png"
ln -sf "usr/bin/${EXE_NAME}" "$APPDIR/AppRun"

echo "==> running appimagetool"
if ! command -v appimagetool &> /dev/null; then
  echo "error: appimagetool not found on PATH."
  echo "download it from https://github.com/AppImage/AppImageKit/releases"
  exit 1
fi

appimagetool "$APPDIR" "build/linux/${APP_NAME}-x86_64.AppImage"

echo "==> done: build/linux/${APP_NAME}-x86_64.AppImage"
