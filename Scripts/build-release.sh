#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="${MDLOOK_DERIVED_DATA_DIR:-$ROOT_DIR/DerivedData}"
DIST_DIR="${MDLOOK_DIST_DIR:-$ROOT_DIR/dist}"
PROJECT_FILE="$ROOT_DIR/MDLook.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"
APP_NAME="MDLook.app"
ZIP_NAME="MDLook.zip"
VOLUME_NAME="MDLook"
DMG_NAME="MDLook.dmg"
TEMP_RW_DMG="$DIST_DIR/MDLook-temp.dmg"
DMG_STAGING_DIR="$DIST_DIR/dmg_staging"
DMG_FINAL_PATH="$DIST_DIR/$DMG_NAME"

ensure_project() {
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
}

cleanup() {
  if [[ -n "${DMG_DEVICE:-}" ]]; then
    hdiutil detach "$DMG_DEVICE" >/dev/null 2>&1 || true
  fi
  rm -rf "$DMG_STAGING_DIR"
  rm -f "$TEMP_RW_DMG"
}

ensure_project
trap cleanup EXIT
setopt local_options null_glob

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

echo "Preparing DMG staging directory..."
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"
ditto "$BUILT_APP" "$DMG_STAGING_DIR/$APP_NAME"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

rm -f "$TEMP_RW_DMG" "$DMG_FINAL_PATH"

echo "Creating writable DMG..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDRW \
  "$TEMP_RW_DMG" >/dev/null

echo "Mounting writable DMG..."
for mounted_volume in /Volumes/"$VOLUME_NAME"*; do
  hdiutil detach "$mounted_volume" >/dev/null 2>&1 || true
done
ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_RW_DMG")"
MOUNT_INFO="$(echo "$ATTACH_OUTPUT" | sed -n 's#^\(/dev/[^[:space:]]*\)[[:space:]].*\(/Volumes/.*\)$#\1|\2#p' | tail -n 1)"
DMG_DEVICE="${MOUNT_INFO%%|*}"
DMG_MOUNT_POINT="${MOUNT_INFO#*|}"
DMG_VOLUME_NAME="$(basename "$DMG_MOUNT_POINT")"
if [[ -z "$DMG_DEVICE" || -z "$DMG_MOUNT_POINT" ]]; then
  echo "Failed to mount DMG." >&2
  exit 1
fi

sleep 2

echo "Applying Finder layout..."
osascript <<EOF
tell application "Finder"
  tell disk "$DMG_VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set sidebar width of container window to 0
    set the bounds of container window to {120, 120, 760, 500}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 14
    set position of item "$APP_NAME" of container window to {180, 210}
    set position of item "Applications" of container window to {460, 210}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

sync
hdiutil detach "$DMG_DEVICE" >/dev/null
unset DMG_DEVICE

echo "Compressing final DMG..."
hdiutil convert "$TEMP_RW_DMG" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_FINAL_PATH" >/dev/null

cat <<EOF

Release packages created:
  ZIP:  $DIST_DIR/$ZIP_NAME
  DMG:  $DMG_FINAL_PATH

This local package is unsigned/not notarized for public distribution.
For local testing, mount the DMG and drag MDLook.app to Applications, open it once,
then enable the extension and refresh Quick Look:
  pluginkit -e use -i com.sokei.MDLook.MDLookExtension
  qlmanage -r
  qlmanage -r cache
  killall Finder
EOF
