HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=2000
SAVEHIST=2000

# Platform-specific setup
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Antidote
export ANTIDOTE_HOME="${ANTIDOTE_HOME:-$HOME/.antidote}"
if [[ ! -d "$ANTIDOTE_HOME" ]]; then
  git clone https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
fi
source "$ANTIDOTE_HOME/antidote.zsh"
ZSH_PLUGIN_FILE="$HOME/.zsh/.zsh_plugins.txt"
ZSH_PLUGIN_OUTPUT="$HOME/.zsh/.zsh_plugins.zsh"
if [[ -s "$ZSH_PLUGIN_FILE" && (! -f "$ZSH_PLUGIN_OUTPUT" || "$ZSH_PLUGIN_FILE" -nt "$ZSH_PLUGIN_OUTPUT") ]]; then
  antidote bundle < "$ZSH_PLUGIN_FILE" > "$ZSH_PLUGIN_OUTPUT"
fi
[[ -f "$ZSH_PLUGIN_OUTPUT" ]] && source "$ZSH_PLUGIN_OUTPUT"

# Prompt
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_LOG=error
  eval "$(starship init zsh)"
fi

setopt AUTO_CD APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY EXTENDED_HISTORY
setopt INTERACTIVE_COMMENTS AUTO_PUSHD PUSHD_IGNORE_DUPS COMPLETE_IN_WORD ALWAYS_TO_END

source ~/.zsh/aliases.zsh

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/bash_completion" ] && . "/opt/homebrew/opt/nvm/bash_completion"
