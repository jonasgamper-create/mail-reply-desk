#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
BIN_DIR="$TOOLS_DIR/bin"
mkdir -p "$BIN_DIR"

find_gh() {
  if command -v gh >/dev/null 2>&1; then
    command -v gh
    return
  fi
  if [[ -x "$BIN_DIR/gh" ]]; then
    printf '%s\n' "$BIN_DIR/gh"
    return
  fi
  return 1
}

install_gh() {
  local arch asset_url tmp_dir zip_path extracted
  arch="$(uname -m)"
  case "$arch" in
    arm64) arch="arm64" ;;
    x86_64) arch="amd64" ;;
    *) echo "Unsupported macOS architecture: $arch" >&2; exit 1 ;;
  esac

  echo "Installing GitHub CLI locally into $TOOLS_DIR ..."
  tmp_dir="$(mktemp -d)"
  zip_path="$tmp_dir/gh.zip"
  asset_url="$(
    curl -fsSL https://api.github.com/repos/cli/cli/releases/latest |
      sed -nE "s/.*\"browser_download_url\": \"([^\"]*gh_[^\"]*_macOS_${arch}\\.zip)\".*/\\1/p" |
      head -n 1
  )"

  if [[ -z "$asset_url" ]]; then
    echo "Could not find a GitHub CLI macOS ${arch} release asset." >&2
    exit 1
  fi

  curl -fL "$asset_url" -o "$zip_path"
  ditto -x -k "$zip_path" "$tmp_dir"
  extracted="$(find "$tmp_dir" -type f -path "*/bin/gh" -perm -111 | head -n 1)"
  if [[ -z "$extracted" ]]; then
    echo "Downloaded GitHub CLI, but no gh binary was found." >&2
    exit 1
  fi

  cp "$extracted" "$BIN_DIR/gh"
  chmod +x "$BIN_DIR/gh"
  echo "Installed: $BIN_DIR/gh"
}

if ! GH_BIN="$(find_gh)"; then
  install_gh
  GH_BIN="$(find_gh)"
fi

echo "GitHub CLI: $("$GH_BIN" --version | head -n 1)"

if [[ "${1:-}" == "--install-only" ]]; then
  exit 0
fi

if ! "$GH_BIN" auth status >/dev/null 2>&1; then
  echo "GitHub login is required. A browser/device login will open now."
  "$GH_BIN" auth login --hostname github.com --git-protocol https --web --scopes repo
fi

"$GH_BIN" auth setup-git
cd "$ROOT_DIR"
git push
