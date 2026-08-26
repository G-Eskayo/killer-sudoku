#!/bin/bash
# Builds KillerSudoku via SPM and wraps it in a real .app bundle, then launches it via `open`.
#
# `swift run` alone launches a bare Unix process with no Info.plist / bundle identity, which
# means it never gets proper macOS app activation (no Dock icon, doesn't reliably become the
# key/frontmost app, keyboard focus is unreliable). Wrapping the built binary in a minimal
# .app bundle and launching it with `open` fixes that — see docs/adr/0004.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
APP_NAME="KillerSudoku"
APP_BUNDLE=".build/${APP_NAME}.app"
BUNDLE_ID="me.gileskayo.killersudoku"

echo "Building ($CONFIG)..."
swift build -c "$CONFIG"

BINARY_PATH=".build/arm64-apple-macosx/${CONFIG}/${APP_NAME}"
if [ ! -f "$BINARY_PATH" ]; then
    # Fall back to whatever arch swift build actually produced.
    BINARY_PATH="$(swift build -c "$CONFIG" --show-bin-path)/${APP_NAME}"
fi

echo "Assembling app bundle at ${APP_BUNDLE}..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>Killer Sudoku</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.puzzle-games</string>
</dict>
</plist>
PLIST

echo "Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Launching..."
open "$APP_BUNDLE"
