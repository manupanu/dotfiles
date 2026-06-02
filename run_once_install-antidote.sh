#!/bin/bash
set -e

if [[ -d "$HOME/.antidote" ]]; then
  echo "Antidote already installed"
  exit 0
fi

git clone https://github.com/mattmc3/antidote.git "$HOME/.antidote"
echo "Antidote installed"
