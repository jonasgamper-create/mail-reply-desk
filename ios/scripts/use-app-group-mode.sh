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
GROUP_ID="group.com.jonasgamper.mailreplydesk"

for file in "${ENTITLEMENT_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Fehlt: $file"
    exit 1
  fi
  /usr/libexec/PlistBuddy -c "Delete :$GROUP_KEY" "$file" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :$GROUP_KEY array" "$file"
  /usr/libexec/PlistBuddy -c "Add :$GROUP_KEY:0 string $GROUP_ID" "$file"
  plutil -lint "$file"
done

echo "App-Group-Modus aktiv: $GROUP_ID ist wieder in den Entitlements."
