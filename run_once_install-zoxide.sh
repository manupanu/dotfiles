#!/bin/bash
# Install zoxide for directory jumping
set -e

if command -v zoxide >/dev/null 2>&1; then
  echo "✓ zoxide already installed: $(zoxide --version)"
  exit 0
fi

echo "Installing zoxide..."

case "$(uname -s)" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install zoxide
    elif command -v cargo >/dev/null 2>&1; then
      cargo install zoxide --locked
    else
      echo "Error: Please install Homebrew or Cargo on macOS"
      exit 1
    fi
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y zoxide
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y zoxide
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm zoxide
    elif command -v cargo >/dev/null 2>&1; then
      cargo install zoxide --locked
    else
      curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if command -v scoop >/dev/null 2>&1; then
      scoop install zoxide
    elif command -v winget >/dev/null 2>&1; then
      winget install zoxide
    elif command -v cargo >/dev/null 2>&1; then
      cargo install zoxide --locked
    else
      echo "Error: Please install scoop, winget, or cargo on Windows"
      exit 1
    fi
    ;;
  *)
    echo "Error: Unsupported operating system"
    exit 1
    ;;
esac

if command -v zoxide >/dev/null 2>&1; then
  echo "✓ zoxide installed successfully: $(zoxide --version)"
else
  echo "✗ zoxide installation failed"
  exit 1
fi
