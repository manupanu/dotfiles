# Editor & env
export EDITOR="code --reuse-window --wait ."
export VISUAL="code --reuse-window --wait ."
export PIPENV_VENV_IN_PROJECT=1

# PATH
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "/usr/local/bin" ]] && PATH="/usr/local/bin:$PATH"
export PATH
