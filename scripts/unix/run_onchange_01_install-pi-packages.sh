#!/bin/sh
set -e

# Install Pi packages listed in settings.json
# This runs when settings.json changes (onchange)

# Load nvm if available so pi (installed via npm) can find node
for init in /usr/share/nvm/init-nvm.sh "$HOME/.nvm/nvm.sh" "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" /opt/homebrew/opt/nvm/nvm.sh; do
  if [ -s "$init" ]; then
    . "$init"
    nvm use --lts --silent 2>/dev/null || true
    break
  fi
done

if ! command -v pi >/dev/null 2>&1; then
  echo "Pi not found — re-run: chezmoi apply" >&2
  exit 1
fi

echo "Installing Pi packages from settings..."
pi update --extensions