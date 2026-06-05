#!/bin/bash
# Install Pi coding agent globally via npm
# Uses node managed by nvm (not pi's bundled node)
set -e

# ── Load nvm ──────────────────────────────────────────────────────────
# Already loaded?
if command -v nvm >/dev/null 2>&1; then
  :
# Arch: system nvm package
elif [[ -s "/usr/share/nvm/init-nvm.sh" ]]; then
  . "/usr/share/nvm/init-nvm.sh"
# macOS Homebrew
elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  . "/opt/homebrew/opt/nvm/nvm.sh"
# XDG or ~/.nvm
elif [[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" ]]; then
  export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
  . "$NVM_DIR/nvm.sh"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  . "$NVM_DIR/nvm.sh"
# Install nvm
else
  echo "nvm not found — installing..."
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install nvm && mkdir -p "$HOME/.nvm"
    export NVM_DIR="$HOME/.nvm"
    . "/opt/homebrew/opt/nvm/nvm.sh"
  elif [[ "$(uname -s)" == "Linux" ]] && command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm nvm
    . "/usr/share/nvm/init-nvm.sh"
  elif [[ "$(uname -s)" == "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
    export NVM_DIR="$HOME/.nvm" && mkdir -p "$NVM_DIR"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
    . "$NVM_DIR/nvm.sh"
  elif [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN)$ ]]; then
    command -v scoop >/dev/null 2>&1 && scoop install nvm || { echo "✗ Install nvm via: scoop install nvm" >&2; exit 1; }
  else
    export NVM_DIR="$HOME/.nvm" && mkdir -p "$NVM_DIR"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
    . "$NVM_DIR/nvm.sh"
  fi
fi

# ── Install node if needed (skip on Windows — nvm-windows handles it) ──
if [[ ! "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN)$ ]]; then
  if ! command -v node >/dev/null 2>&1; then
    echo "No Node.js — installing latest LTS..."
    nvm install --lts
    nvm use --lts
  fi
fi

# ── Install pi ─────────────────────────────────────────────────────────
if command -v pi >/dev/null 2>&1; then
  echo "✓ Pi already installed: $(pi --version 2>/dev/null || echo 'unknown')"
  exit 0
fi

echo "Installing Pi..."
npm install -g @earendil-works/pi-coding-agent

echo "✓ Pi installed"
echo "Run 'pi login' to set up API keys."