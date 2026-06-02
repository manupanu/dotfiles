#!/bin/bash
# Rebuild zsh completion cache when zshrc changes
set -e

if [ -d "$HOME/.zsh" ]; then
  rm -f "$HOME/.zsh/.zcompdump"*
  echo "Cleared zsh completion cache"
fi
