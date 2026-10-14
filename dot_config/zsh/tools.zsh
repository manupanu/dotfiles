# Interactive prompt, navigation, and CLI completion tools

# GitHub Copilot CLI completion (after plugins initialize compinit)
if command -v copilot >/dev/null 2>&1; then
  source <(copilot completion zsh)
fi

# Pi CLI completion
if command -v pi >/dev/null 2>&1 && [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/completions/pi.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/completions/pi.zsh"
fi

# Zoxide (smarter cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
