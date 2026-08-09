# Packaging 42 Guides for distribution

Scripts and config for producing installable builds on each desktop platform.
None of these are run automatically — build them locally on the matching OS.

## Windows — MSIX

Config lives in `pubspec.yaml` under `msix_config`. Build with:

```
flutter pub get
flutter pub run msix:create
```

The app icon (`assets/icon/app_icon_256.png`) is currently the default
Flutter icon extracted from `windows/runner/resources/app_icon.ico` — swap
it for real "42 Guides" branding when available.

## Linux — AppImage

```
./packaging/linux/build_appimage.sh
```

Requires `appimagetool` on PATH. Produces
`build/linux/42Guides-x86_64.AppImage`.

## macOS — DMG

```
./packaging/macos/build_dmg.sh
```

Requires `create-dmg` (`brew install create-dmg`), and must run on macOS
with Xcode command line tools installed. Produces `build/macos/42 Guides.dmg`.

This build is **unsigned and not notarized** — Gatekeeper will block it on
other Macs unless the user right-clicks → Open. Proper distribution needs
an Apple Developer ID to sign and notarize, which isn't scripted here.
