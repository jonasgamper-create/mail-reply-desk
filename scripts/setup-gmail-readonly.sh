#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
ENV_FILE="$BACKEND_DIR/.env"
EXAMPLE_FILE="$BACKEND_DIR/.env.example"
PORT="${PORT:-8787}"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
  echo "Created $ENV_FILE"
fi

if ! grep -q '^GOOGLE_CLIENT_ID=.\+' "$ENV_FILE" || ! grep -q '^GOOGLE_CLIENT_SECRET=.\+' "$ENV_FILE"; then
  echo "Google OAuth credentials are missing in backend/.env."
  echo "Opening Google Cloud credentials page. Create a Web application OAuth client."
  echo "Redirect URI: http://127.0.0.1:${PORT}/oauth/google/callback"
  open "https://console.cloud.google.com/apis/credentials" >/dev/null 2>&1 || true
  echo
  echo "After creating the OAuth client, fill these values in backend/.env:"
  echo "GOOGLE_CLIENT_ID=..."
  echo "GOOGLE_CLIENT_SECRET=..."
  exit 2
fi

cd "$BACKEND_DIR"
echo "Starting Gmail Read-only backend on http://127.0.0.1:${PORT}"
echo "Opening OAuth login..."
(sleep 1 && open "http://127.0.0.1:${PORT}/auth/google" >/dev/null 2>&1 || true) &
npm start
