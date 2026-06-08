#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$ROOT_DIR/ios/MailReplyDesk.xcodeproj"
SCHEME="MailReplyDesk"
SCREENSHOT_DIR="/tmp/mailreplydesk-preflight"
SCREENSHOT_PATH="$SCREENSHOT_DIR/settings-simulator.png"

mkdir -p "$SCREENSHOT_DIR"

echo "== Xcode =="
xcodebuild -version

echo
echo "== Simulator auswaehlen =="
SIM_JSON="$(mktemp /tmp/mailreply-simulators.XXXXXX.json)"
trap 'rm -f "$SIM_JSON"' EXIT
xcrun simctl list devices available --json > "$SIM_JSON"

SIM_ID="$(python3 - "$SIM_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)
devices = []
for runtime_devices in payload.get("devices", {}).values():
    devices.extend(runtime_devices)

booted = [
    device for device in devices
    if device.get("isAvailable") and device.get("state") == "Booted" and device.get("name", "").startswith("iPhone")
]
preferred = [
    device for device in devices
    if device.get("isAvailable") and device.get("name") == "iPhone 17 Pro"
]
fallback = [
    device for device in devices
    if device.get("isAvailable") and device.get("name", "").startswith("iPhone")
]

for group in (booted, preferred, fallback):
    if group:
        print(group[0]["udid"])
        break
PY
)"

if [[ -z "$SIM_ID" ]]; then
  echo "Kein verfuegbarer iPhone Simulator gefunden."
  exit 1
fi

echo "Simulator: $SIM_ID"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_ID" -b >/dev/null

echo
echo "== Simulator Build =="
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$SIM_ID" \
  build

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/Debug-iphonesimulator/MailReplyDesk.app" -type d -print | sort | tail -n 1)"

if [[ -z "$APP_PATH" ]]; then
  echo "Simulator Build erfolgreich, aber MailReplyDesk.app wurde nicht gefunden."
  exit 1
fi

echo
echo "== Simulator Install und Start =="
xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl launch "$SIM_ID" com.jonasgamper.mailreplydesk
sleep 2
xcrun simctl io "$SIM_ID" screenshot "$SCREENSHOT_PATH" >/dev/null
echo "Screenshot: $SCREENSHOT_PATH"

echo
echo "== Echtes iPhone pruefen =="
DEVICES_JSON="$(mktemp /tmp/mailreply-devices.XXXXXX.json)"
trap 'rm -f "$SIM_JSON" "$DEVICES_JSON"' EXIT
xcrun devicectl list devices --json-output "$DEVICES_JSON" >/dev/null || true

DEVICE_ID="$(python3 - "$DEVICES_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)

for device in payload.get("result", {}).get("devices", []):
    hardware = device.get("hardwareProperties", {})
    connection = device.get("connectionProperties", {})
    is_connected = (
        connection.get("tunnelState") == "connected"
        or connection.get("transportType") in {"wired", "localNetwork"}
    )
    if is_connected and hardware.get("deviceType") == "iPhone":
        print(hardware.get("udid", "") or device.get("identifier", ""))
        break
PY
)"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Kein online verbundenes iPhone gefunden. Das ist unterwegs/remote normal."
  echo "Nachmittag: iPhone entsperren, Kabel verbinden, Trust bestaetigen, dann diesen Script erneut starten."
  exit 0
fi

echo "iPhone online: $DEVICE_ID"
echo
echo "== Installation auf echtes iPhone =="
"$ROOT_DIR/ios/scripts/build-install-personal-team.sh" "$DEVICE_ID"
