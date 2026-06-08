#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_ENTITLEMENTS="$ROOT_DIR/ios/MailReplyDesk/App/MailReplyDesk.entitlements"
ENTITLEMENT_FILES=(
  "$APP_ENTITLEMENTS"
  "$ROOT_DIR/ios/MailReplyDesk/MailReplyKeyboard/MailReplyKeyboard.entitlements"
  "$ROOT_DIR/ios/MailReplyDesk/MailReplyMailKeyboard/MailReplyMailKeyboard.entitlements"
  "$ROOT_DIR/ios/MailReplyDesk/MailReplyChatKeyboard/MailReplyChatKeyboard.entitlements"
)
GROUP_KEY="com.apple.security.application-groups"

for file in "${ENTITLEMENT_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Fehlt: $file"
    exit 1
  fi
  /usr/libexec/PlistBuddy -c "Delete :$GROUP_KEY" "$file" 2>/dev/null || true
  plutil -lint "$file"
done

echo "Free-Account-Modus aktiv: App Groups sind aus den Entitlements entfernt."
echo "Hinweis: Profil-Sync zwischen App und Tastatur ist damit nicht garantiert."
