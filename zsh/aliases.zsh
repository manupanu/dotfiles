# ~/.config/zsh/custom/aliases.zsh
# Contains custom aliases

# Navigation
alias ..='z ..'
alias ...='z ../..'
alias ....='z ../../..'
alias .....='z ../../../..'

alias cd='z' # Use zoxide for cd command

# Listing files (using eza with icons)
# Requires a Nerd Font installed and configured in the terminal
alias ls='eza -a --group-directories-first --icons=always' # List all files, group dirs, add icons
alias ll='eza -lgh --icons=always' # Long listing format, group dirs, header, icons
alias la='eza -A --icons=always' # List almost all entries, icons
alias l='eza -F --icons=always' # List entries by columns, icons, classify

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit -am'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'

# Make directory and change into it
mcd() {
    mkdir -p -- "$1" && cd -P -- "$1"
}

# Edit config files (adjust editor if needed)
alias ezshrc='${EDITOR:-nvim} ~/.zshrc'
alias ealiases='${EDITOR:-nvim} ~/.config/zsh/custom/aliases.zsh' 

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dls='docker container ls'
alias di='docker images'
alias dprune='docker system prune -af'

# System monitoring
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='netstat -tulanp'
alias mem='ps auxf | sort -nr -k 4 | head -10' # Top 10 memory consuming processes
alias cpu='ps auxf | sort -nr -k 3 | head -10' # Top 10 CPU consuming processes

# Network tools
alias myip='curl -s http://ipecho.net/plain; echo'
alias localip="ip -br address"
alias ping='ping -c 5'
alias wget='wget -c' # Resume download by default

# Quick directory jumps
alias dot='cd ~/.dotfiles'
alias dl='cd ~/Downloads'
alias doc='cd ~/Documents'

# Utilities
alias c='clear'
alias h='history'
alias sz='source ~/.zshrc'
alias path='echo -e ${PATH//:/\\n}' # Print each PATH entry on a separate line
alias now='date +"%T"'
alias timestamp='date +"%Y%m%d_%H%M%S"'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias md='mkdir -p'

# Add keyfile for sbc-hid
alias sbc-hid='sbc-hid --keys ~/Developer/SBC-Tools/keys.json'