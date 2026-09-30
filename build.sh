#!/bin/zsh
set -eu
cd "$(dirname "$0")"
BUILD_DIR=$(mktemp -d /private/tmp/keyboardclean.XXXXXX)
APP="$BUILD_DIR/键盘清洁.app"
trap 'rm -rf "$BUILD_DIR"' EXIT
mkdir -p "$PWD/dist"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
swift -module-cache-path "$PWD/.build-cache" icon.swift "$BUILD_DIR/AppIcon.iconset"
python3 pack-icon.py "$BUILD_DIR/AppIcon.iconset" "$APP/Contents/Resources/AppIcon.icns"

swiftc -target arm64-apple-macos13.0 -module-cache-path "$PWD/.build-cache" main.swift -o "$APP/Contents/MacOS/KeyboardClean" -framework Cocoa -framework ApplicationServices
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>KeyboardClean</string>
<key>CFBundleIdentifier</key><string>local.keyboardclean.mac</string>
<key>CFBundleName</key><string>键盘清洁</string>
<key>CFBundleDisplayName</key><string>键盘清洁</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>1.2</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAccessibilityUsageDescription</key><string>清洁键盘期间拦截按键，避免误输入。不保存按键内容。</string>
</dict></plist>
PLIST
xattr -cr "$APP"
SIGN_IDENTITY="${KEYBOARD_CLEAN_SIGN_IDENTITY:--}"
codesign --force --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --strict "$APP"
ditto -c -k --keepParent "$APP" "$PWD/dist/KeyboardClean-1.2-arm64.zip"
ditto "$APP" "$PWD/dist/键盘清洁.app"

