#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="${MDLOOK_DERIVED_DATA_DIR:-$ROOT_DIR/DerivedData}"
INSTALL_DIR="${MDLOOK_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="MDLook.app"
APP_BUNDLE_ID="com.sokei.MDLook"
EXTENSION_BUNDLE_ID="com.sokei.MDLook.MDLookExtension"
PROJECT_FILE="$ROOT_DIR/MDLook.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"

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

echo "Building MDLook..."
xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme MDLook \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build

BUILT_APP="$DERIVED_DATA_DIR/Build/Products/Debug/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "Build finished, but $BUILT_APP was not found." >&2
  exit 1
fi

echo "Installing to $INSTALL_DIR/$APP_NAME..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME"
ditto "$BUILT_APP" "$INSTALL_DIR/$APP_NAME"

echo "Registering app and enabling Quick Look extension..."
open -gj "$INSTALL_DIR/$APP_NAME"
pluginkit -e use -i "$EXTENSION_BUNDLE_ID" || true

echo "Refreshing Quick Look and Finder..."
qlmanage -r >/dev/null
qlmanage -r cache >/dev/null
killall Finder >/dev/null 2>&1 || true

cat <<EOF

MDLook development install complete.

Installed app:
  $INSTALL_DIR/$APP_NAME

Bundle identifiers:
  App:       $APP_BUNDLE_ID
  Extension: $EXTENSION_BUNDLE_ID

Manual verification:
  qlmanage -p "$ROOT_DIR/Samples/basic.md"
  qlmanage -p "$ROOT_DIR/Samples/regression.md"
  qlmanage -p "$ROOT_DIR/Samples/images.md"

Finder verification:
  Select a .md file and press Space.
EOF
