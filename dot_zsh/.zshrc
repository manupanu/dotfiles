zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
zsh_plugins_src=${ZDOTDIR:-$HOME}/.zsh_plugins.txt

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt AUTO_CD
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt INTERACTIVE_COMMENTS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

if [[ ! -f $HOME/.antidote/antidote.zsh ]]; then
  echo "antidote is missing at $HOME/.antidote. Run 'chezmoi apply' to install it." >&2
else
  if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins_src} ]]; then
    (
      source "$HOME/.antidote/antidote.zsh"
      antidote bundle <"${zsh_plugins_src}" >|"${zsh_plugins}.zsh"
    )
  fi

  source "${zsh_plugins}.zsh"
fi

autoload -Uz promptinit && promptinit
prompt pure

# Aliases
source ~/.zsh/aliases

# zoxide
eval "$(zoxide init zsh)"
