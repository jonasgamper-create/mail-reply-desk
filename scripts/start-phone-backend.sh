#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
ENV_FILE="$BACKEND_DIR/.env"
EXAMPLE_FILE="$BACKEND_DIR/.env.example"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
  echo "Created $ENV_FILE"
fi

cd "$BACKEND_DIR"
echo "Starting Gmail backend for iPhone on the local network..."
echo "Use the printed iPhone Backend URL inside the iPhone app."
HOST=0.0.0.0 npm start
