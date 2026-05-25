#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="${MDLOOK_DERIVED_DATA_DIR:-$ROOT_DIR/DerivedData}"
DIST_DIR="${MDLOOK_DIST_DIR:-$ROOT_DIR/dist}"
PROJECT_FILE="$ROOT_DIR/MDLook.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"
APP_NAME="MDLook.app"
ZIP_NAME="MDLook.zip"

if [[ ! -d "$PROJECT_FILE" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    echo "Generating Xcode project with XcodeGen..."
    (cd "$ROOT_DIR" && xcodegen generate)
  else
    echo "MDLook.xcodeproj is missing and xcodegen is not installed." >&2
    echo "Install it with: brew install xcodegen" >&2
    exit 1
  fi
elif [[ "$PROJECT_YML" -nt "$PROJECT_FILE/project.pbxproj" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    echo "Regenerating Xcode project because project.yml is newer..."
    (cd "$ROOT_DIR" && xcodegen generate)
  else
    echo "project.yml is newer than the Xcode project, but xcodegen is not installed." >&2
    echo "Install it with: brew install xcodegen" >&2
    exit 1
  fi
fi

echo "Building Release app..."
xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme MDLook \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build

BUILT_APP="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "Build finished, but $BUILT_APP was not found." >&2
  exit 1
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto "$BUILT_APP" "$DIST_DIR/$APP_NAME"

echo "Creating $DIST_DIR/$ZIP_NAME..."
(cd "$DIST_DIR" && ditto -c -k --sequesterRsrc --keepParent "$APP_NAME" "$ZIP_NAME")

echo "Creating $DIST_DIR/MDLook.dmg..."
DMG_TEMP_DIR="$DIST_DIR/dmg_temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
ditto "$BUILT_APP" "$DMG_TEMP_DIR/$APP_NAME"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

DMG_PATH="$DIST_DIR/MDLook.dmg"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "MDLook" \
  -srcfolder "$DMG_TEMP_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_TEMP_DIR"

cat <<EOF

Release packages created:
  ZIP:  $DIST_DIR/$ZIP_NAME
  DMG:  $DMG_PATH

This local package is unsigned/not notarized for public distribution.
For local testing, mount the DMG and drag MDLook.app to Applications (or unzip the ZIP), open it once,
then enable the extension and refresh Quick Look:
  pluginkit -e use -i com.sokei.MDLook.MDLookExtension
  qlmanage -r
  qlmanage -r cache
  killall Finder
EOF
