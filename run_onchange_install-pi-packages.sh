#!/bin/sh
set -e

# Install Pi packages listed in settings.json
# This runs when settings.json changes (onchange)
echo "Installing Pi packages from settings..."
pi update --extensions