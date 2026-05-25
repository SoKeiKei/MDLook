#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MDLook.app"
EXTENSION_NAME="MDLookExtension.appex"
APP_BUNDLE_ID="com.sokei.MDLook"
EXTENSION_BUNDLE_ID="com.sokei.MDLook.MDLookExtension"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
PREFERENCES_DIR="$HOME/Library/Application Support/MDLook"
EXTENSION_CONTAINER_DIR="$HOME/Library/Containers/$EXTENSION_BUNDLE_ID"

declare -a SEARCH_ROOTS=(
  "/Applications"
  "$HOME/Applications"
  "$HOME/Desktop"
  "$HOME/Downloads"
  "$HOME/Documents"
  "$ROOT_DIR"
  "$HOME/Library/Developer/Xcode/DerivedData"
)

find_paths() {
  local target_name="$1"
  local root
  for root in "${SEARCH_ROOTS[@]}"; do
    [[ -e "$root" ]] || continue
    find "$root" -type d -name "$target_name" -print 2>/dev/null
  done | sort -u
}

echo "=== Starting Complete Uninstallation of MDLook ==="

APP_PATHS=()
while IFS= read -r path; do
  [[ -n "$path" ]] && APP_PATHS+=("$path")
done < <(find_paths "$APP_NAME")

EXTENSION_PATHS=()
while IFS= read -r path; do
  [[ -n "$path" ]] && EXTENSION_PATHS+=("$path")
done < <(find_paths "$EXTENSION_NAME")

echo "Disabling and unregistering Quick Look extension..."
pluginkit -e ignore -i "$EXTENSION_BUNDLE_ID" >/dev/null 2>&1 || true
for extension_path in "${EXTENSION_PATHS[@]}"; do
  echo "Unregistering $extension_path"
  pluginkit -r "$extension_path" >/dev/null 2>&1 || true
done

echo "Unregistering app bundles from Launch Services..."
for app_path in "${APP_PATHS[@]}"; do
  echo "Unregistering $app_path"
  "$LSREGISTER" -u "$app_path" >/dev/null 2>&1 || true
done

echo "Removing preferences and container data..."
defaults delete "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
defaults delete "$EXTENSION_BUNDLE_ID" >/dev/null 2>&1 || true
rm -rf "$PREFERENCES_DIR" >/dev/null 2>&1 || true
rm -rf "$EXTENSION_CONTAINER_DIR/Data/Library/Application Support/MDLook" >/dev/null 2>&1 || true
rm -rf "$EXTENSION_CONTAINER_DIR" >/dev/null 2>&1 || true

echo "Deleting extension bundles..."
for extension_path in "${EXTENSION_PATHS[@]}"; do
  if [[ -d "$extension_path" ]]; then
    echo "Removing $extension_path"
    rm -rf "$extension_path"
  fi
done

echo "Deleting app bundles..."
for app_path in "${APP_PATHS[@]}"; do
  if [[ -d "$app_path" ]]; then
    echo "Removing $app_path"
    rm -rf "$app_path"
  fi
done

echo "Clearing Quick Look cache..."
qlmanage -r >/dev/null
qlmanage -r cache >/dev/null
killall quicklookd >/dev/null 2>&1 || true
killall QuickLookUIService >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

echo "Verifying removal..."
if pluginkit -m -i "$EXTENSION_BUNDLE_ID" | grep -q "$EXTENSION_BUNDLE_ID"; then
  echo "Warning: pluginkit still reports $EXTENSION_BUNDLE_ID. A logout/login may be needed to clear System Settings UI cache." >&2
fi

REMAINING_APPS="$(find_paths "$APP_NAME" || true)"
REMAINING_EXTENSIONS="$(find_paths "$EXTENSION_NAME" || true)"

if [[ -n "$REMAINING_APPS" || -n "$REMAINING_EXTENSIONS" ]]; then
  echo "Warning: some MDLook artifacts remain:" >&2
  [[ -n "$REMAINING_APPS" ]] && echo "$REMAINING_APPS" >&2
  [[ -n "$REMAINING_EXTENSIONS" ]] && echo "$REMAINING_EXTENSIONS" >&2
else
  echo "No MDLook app bundles or extension bundles remain in scanned locations."
fi

echo "=== MDLook Uninstallation Complete! ==="
echo "You can now mount your DMG and perform a fresh install test."
