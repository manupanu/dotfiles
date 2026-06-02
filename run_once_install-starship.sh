#!/bin/bash
set -e

if command -v starship >/dev/null 2>&1; then
  echo "Starship already installed"
  exit 0
fi

if [[ "$(uname)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  brew install starship
  exit 0
fi

curl -sS https://starship.rs/install.sh | sh -s -- --yes
