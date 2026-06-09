# Homebrew (macOS)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv zsh)"
fi

# Editor & env
export EDITOR="code --reuse-window --wait ."
export VISUAL="code --reuse-window --wait ."
export PIPENV_VENV_IN_PROJECT=1

# PATH
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
export PATH
