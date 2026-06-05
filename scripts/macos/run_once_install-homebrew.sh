#!/bin/bash
# Install Homebrew on macOS only
set -e

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Homebrew is macOS-only — skipping"
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  echo "✓ Homebrew already installed: $(brew --version | head -1)"
  exit 0
fi

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH for the current session
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv bash)"
fi

echo "✓ Homebrew installed: $(brew --version | head -1)"