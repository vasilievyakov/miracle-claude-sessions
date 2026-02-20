#!/bin/bash
# Build ClaudeSessions.app bundle from SwiftPM release binary
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/.build"
APP_NAME="ClaudeSessions"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
VERSION="${1:-1.0.0}"

echo "Building $APP_NAME v$VERSION..."

# 1. Build release binary
swift build -c release --package-path "$ROOT_DIR"

# 2. Create .app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy binary
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 4. Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Sessions</string>
    <key>CFBundleIdentifier</key>
    <string>com.vasilievyakov.claudesessions</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Yakov Vasiliev. MIT License.</string>
</dict>
</plist>
PLIST

# 5. Copy entitlements (for reference, not enforced without codesign)
cp "$ROOT_DIR/ClaudeSessions.entitlements" "$APP_BUNDLE/Contents/Resources/"

# 6. Create zip for distribution
cd "$BUILD_DIR"
rm -f "$APP_NAME.app.zip"
zip -r -y "$APP_NAME.app.zip" "$APP_NAME.app"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo "✓ Zip:   $BUILD_DIR/$APP_NAME.app.zip"
echo "  Size:  $(du -h "$BUILD_DIR/$APP_NAME.app.zip" | cut -f1)"
