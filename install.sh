#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/manupanu/dotfiles.git"

echo -e "${BLUE}==>${NC} Starting dotfiles installation..."

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error:${NC} git is not installed. Please install git first."
    exit 1
fi

# Clone or update repo
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${BLUE}==>${NC} Dotfiles directory already exists at $DOTFILES_DIR. Updating..."
    cd "$DOTFILES_DIR"
    git pull
else
    echo -e "${BLUE}==>${NC} Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
fi

# Run bootstrap
if [ -f "./bootstrap.sh" ]; then
    echo -e "${BLUE}==>${NC} Running bootstrap script..."
    chmod +x ./bootstrap.sh
    ./bootstrap.sh
else
    echo -e "${RED}Error:${NC} bootstrap.sh not found in $DOTFILES_DIR"
    exit 1
fi

echo -e "${GREEN}==>${NC} Installation complete!"
