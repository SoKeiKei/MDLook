#!/bin/bash
# MDLook Complete Uninstaller
set -euo pipefail

APP_NAME="MDLook.app"
EXTENSION_BUNDLE_ID="com.sokei.MDLook.MDLookExtension"
APP_BUNDLE_ID="com.sokei.MDLook"

echo "=== Starting Complete Uninstallation of MDLook ==="

# 1. Disable and unregister the Quick Look extension
echo "Unregistering Quick Look extension..."
pluginkit -e ignore -i "$EXTENSION_BUNDLE_ID" || true
pluginkit -r "/Applications/$APP_NAME/Contents/PlugIns/MDLookExtension.appex" 2>/dev/null || true
pluginkit -r "$HOME/Applications/$APP_NAME/Contents/PlugIns/MDLookExtension.appex" 2>/dev/null || true

# 2. Unregister from Launch Services database
echo "Unregistering from Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "/Applications/$APP_NAME" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$HOME/Applications/$APP_NAME" 2>/dev/null || true

# 3. Clean up user preferences/defaults
echo "Removing user preferences/defaults..."
defaults delete "$APP_BUNDLE_ID" 2>/dev/null || true
defaults delete "$EXTENSION_BUNDLE_ID" 2>/dev/null || true

# 4. Remove the application bundle
echo "Deleting application bundles..."
if [ -d "/Applications/$APP_NAME" ]; then
  echo "Removing /Applications/$APP_NAME"
  rm -rf "/Applications/$APP_NAME"
fi
if [ -d "$HOME/Applications/$APP_NAME" ]; then
  echo "Removing $HOME/Applications/$APP_NAME"
  rm -rf "$HOME/Applications/$APP_NAME"
fi

# 5. Clear Quick Look cache and restart Finder
echo "Clearing Quick Look cache..."
qlmanage -r >/dev/null
qlmanage -r cache >/dev/null

echo "Restarting Finder..."
killall Finder >/dev/null 2>&1 || true

echo "=== MDLook Uninstallation Complete! ==="
echo "You can now mount your DMG and perform a fresh install test."
