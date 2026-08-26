# Linux & Arch / CachyOS specific configurations

export FZF_BASE=/usr/share/fzf
export SSH_AUTH_SOCK=~/.1password/agent.sock

# Package management & system aliases
alias update='sudo pacman -Syu'
alias rmpkg='sudo pacman -Rsn'
alias cleanch='sudo pacman -Scc'
alias fixpacman='sudo rm /var/lib/pacman/db.lck'
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias jctl='journalctl -p 3 -xb'
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\\t%n %v' | sort | tail -200 | nl"

# Safely remove orphaned packages
cleanup() {
  local -a orphans
  orphans=("${(@f)$(pacman -Qtdq 2>/dev/null)}")
  if (( ${#orphans[@]} )); then
    sudo pacman -Rsn -- "${orphans[@]}"
  else
    print 'No orphaned packages found.'
  fi
}

# Command-not-found handler via pkgfile
[[ -r /usr/share/doc/pkgfile/command-not-found.zsh ]] && source /usr/share/doc/pkgfile/command-not-found.zsh
