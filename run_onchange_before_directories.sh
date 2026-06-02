#!/bin/bash
# Create necessary directories before applying dotfiles
set -e

mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

echo "Created required directories"
