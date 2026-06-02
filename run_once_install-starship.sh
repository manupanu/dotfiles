#!/bin/bash
# Install Starship prompt
set -e

if command -v starship >/dev/null 2>&1; then
  echo "✓ Starship already installed: $(starship --version 2>/dev/null | head -n1)"
  exit 0
fi

echo "Installing Starship..."

case "$(uname -s)" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install starship
    elif command -v cargo >/dev/null 2>&1; then
      cargo install starship --locked
    else
      curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y starship
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y starship
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm starship
    elif command -v cargo >/dev/null 2>&1; then
      cargo install starship --locked
    else
      curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if command -v scoop >/dev/null 2>&1; then
      scoop install starship
    elif command -v winget >/dev/null 2>&1; then
      winget install starship
    else
      echo "Error: Please install scoop or winget on Windows, or install manually from https://starship.rs"
      exit 1
    fi
    ;;
  *)
    echo "Error: Unsupported operating system"
    exit 1
    ;;
esac

if command -v starship >/dev/null 2>&1; then
  echo "✓ Starship installed successfully: $(starship --version 2>/dev/null | head -n1)"
else
  echo "✗ Starship installation failed"
  exit 1
fi
