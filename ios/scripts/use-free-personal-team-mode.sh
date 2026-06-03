#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_ENTITLEMENTS="$ROOT_DIR/ios/MailReplyDesk/App/MailReplyDesk.entitlements"
KEYBOARD_ENTITLEMENTS="$ROOT_DIR/ios/MailReplyDesk/MailReplyKeyboard/MailReplyKeyboard.entitlements"
GROUP_KEY="com.apple.security.application-groups"

for file in "$APP_ENTITLEMENTS" "$KEYBOARD_ENTITLEMENTS"; do
  if [[ ! -f "$file" ]]; then
    echo "Fehlt: $file"
    exit 1
  fi
  /usr/libexec/PlistBuddy -c "Delete :$GROUP_KEY" "$file" 2>/dev/null || true
  plutil -lint "$file"
done

echo "Free-Account-Modus aktiv: App Groups sind aus den Entitlements entfernt."
echo "Hinweis: Profil-Sync zwischen App und Tastatur ist damit nicht garantiert."
