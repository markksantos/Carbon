#!/usr/bin/env bash
#
# build-app.sh — Assemble a distributable Carbon.app bundle from the SPM build.
#
# Carbon is a pure Swift Package Manager executable. `swift run` is great for
# development, but distribution as a menu bar app needs a real .app bundle with
# an Info.plist (LSUIElement) and an icon. This script builds a release binary
# and wraps it in a proper bundle — no Xcode project required.
#
# Usage:
#   scripts/build-app.sh                 # build unsigned Carbon.app
#   CODESIGN_IDENTITY="Developer ID Application: …" scripts/build-app.sh
#
# Optional environment variables:
#   CONFIGURATION       debug | release   (default: release)
#   CODESIGN_IDENTITY   codesign identity; if set, the bundle is signed with
#                       Hardened Runtime + Carbon.entitlements
#   BUILD_DIR           output directory  (default: ./dist)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-release}"
BUILD_DIR="${BUILD_DIR:-$ROOT/dist}"
APP_NAME="Carbon"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
EXECUTABLE_NAME="Carbon"

echo "==> Building $APP_NAME ($CONFIGURATION) with Swift Package Manager"
swift build -c "$CONFIGURATION" --arch arm64

BIN_PATH="$(swift build -c "$CONFIGURATION" --arch arm64 --show-bin-path)"
EXECUTABLE="$BIN_PATH/$EXECUTABLE_NAME"

if [[ ! -f "$EXECUTABLE" ]]; then
    echo "error: built executable not found at $EXECUTABLE" >&2
    exit 1
fi

echo "==> Assembling bundle at $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# PkgInfo (classic Carbon-era marker, harmless and expected by some tools).
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

# App icon: prefer a prebuilt .icns, otherwise compile it from AppIcon.iconset.
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
elif [[ -d "$ROOT/Resources/AppIcon.iconset" ]]; then
    echo "==> Compiling AppIcon.iconset -> AppIcon.icns"
    iconutil -c icns "$ROOT/Resources/AppIcon.iconset" \
        -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "warning: no app icon found (Resources/AppIcon.icns or AppIcon.iconset)" >&2
fi

# Codesign (optional). Without an identity the bundle runs locally after the
# user removes the quarantine attribute; for distribution set CODESIGN_IDENTITY.
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    echo "==> Codesigning with Hardened Runtime: $CODESIGN_IDENTITY"
    codesign --force --deep --options runtime \
        --entitlements "$ROOT/Resources/Carbon.entitlements" \
        --sign "$CODESIGN_IDENTITY" \
        "$APP_BUNDLE"
    echo "==> Verifying signature"
    codesign --verify --strict --verbose=2 "$APP_BUNDLE"
else
    echo "==> Skipping codesign (CODESIGN_IDENTITY not set) — applying ad-hoc signature"
    codesign --force --deep --sign - "$APP_BUNDLE" || true
fi

echo ""
echo "Done. Bundle: $APP_BUNDLE"
echo "Run it with: open \"$APP_BUNDLE\""
