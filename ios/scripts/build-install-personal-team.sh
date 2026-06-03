#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$ROOT_DIR/ios/MailReplyDesk.xcodeproj"
SCHEME="MailReplyDesk"
DEVICE_ID="${1:-}"

if [[ -z "$DEVICE_ID" ]]; then
  DEVICES_JSON="$(mktemp /tmp/mailreply-devices.XXXXXX.json)"
  trap 'rm -f "$DEVICES_JSON"' EXIT
  xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null
  DEVICE_ID="$(python3 - "$DEVICES_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

for device in payload.get("result", {}).get("devices", []):
    hardware = device.get("hardwareProperties", {})
    connection = device.get("connectionProperties", {})
    is_connected = connection.get("tunnelState") == "connected" or connection.get("transportType") in {"wired", "localNetwork"}
    if is_connected and hardware.get("deviceType") == "iPhone":
        print(hardware.get("udid", "") or device.get("identifier", ""))
        break
PY
)"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "Kein verbundenes iPhone gefunden. Optional UDID als Argument uebergeben."
  exit 1
fi

TEAM_ID="$(defaults read com.apple.dt.Xcode IDEProvisioningTeamManagerLastSelectedTeamID 2>/dev/null || true)"
if [[ -z "$TEAM_ID" ]]; then
  TEAM_ID="$(defaults read com.apple.dt.Xcode IDEProvisioningTeams 2>/dev/null | awk '/teamID/ {print $3; exit}' | tr -d '";' || true)"
fi

if [[ -z "$TEAM_ID" ]]; then
  echo "Keine Xcode Team-ID gefunden. In Xcode unter Settings > Accounts mit Apple-ID anmelden."
  exit 1
fi

echo "Device: $DEVICE_ID"
echo "Team-ID: $TEAM_ID"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  build

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Debug-iphoneos/MailReplyDesk.app" -not -path "*/Index.noindex/*" -type d -print | sort | tail -n 1)"

if [[ -z "$APP_PATH" ]]; then
  echo "Build war erfolgreich, aber MailReplyDesk.app wurde nicht gefunden."
  exit 1
fi

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH" --timeout 120

echo "Installiert: $APP_PATH"
echo "Wenn der Start blockiert: iPhone > Einstellungen > Allgemein > VPN & Geraeteverwaltung > Entwickler vertrauen."
