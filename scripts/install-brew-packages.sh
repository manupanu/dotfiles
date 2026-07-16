#!/bin/sh
set -eu

# Resolve the root directory of the repository
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found, skipping Brewfile install"
  exit 0
fi

echo "Installing Homebrew packages from Brewfile..."
brew bundle --file="$REPO_DIR/Brewfile"
