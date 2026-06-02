#!/bin/bash
# Install Homebrew on macOS
set -e

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Homebrew setup is macOS-only — skipping"
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  echo "✓ Homebrew already installed: $(brew --version | head -n1)"
  exit 0
fi

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH for the current session (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
fi

# Add to PATH for Intel Macs
if [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv bash)"
fi

echo "✓ Homebrew installed: $(brew --version | head -n1)"
