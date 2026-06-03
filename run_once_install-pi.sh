#!/bin/bash
# Install Pi coding agent globally via npm
# Requires Node.js (installed via nvm, which is in the Brewfile)
set -e

# Ensure nvm is loaded
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install a Node LTS version if none is installed
if ! command -v node >/dev/null 2>&1; then
  echo "No Node.js found — installing latest LTS via nvm..."
  nvm install --lts
fi

if command -v pi >/dev/null 2>&1; then
  echo "✓ Pi already installed: $(pi --version 2>/dev/null || echo 'unknown')"
  exit 0
fi

echo "Installing Pi..."
npm install -g @earendil-works/pi-coding-agent

echo "✓ Pi installed: $(pi --version 2>/dev/null || echo 'done')"