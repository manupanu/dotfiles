[[ -o interactive ]] || return

# History settings
HISTFILE="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history share_history hist_ignore_space hist_ignore_dups hist_expire_dups_first hist_save_no_dups hist_reduce_blanks hist_verify

# Exclude noisy commands from shell history
zshaddhistory() {
  local command=${1%%$'\n'}
  case "$command" in
    '&'|bg|fg|c|clear|history|exit|q|pwd|*' --help') return 1 ;;
  esac
  return 0
}
