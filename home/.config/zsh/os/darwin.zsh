# macOS specific configurations

# Homebrew aliases
if command -v brew >/dev/null 2>&1; then
  alias update='brew update && brew upgrade'
  alias cleanch='brew cleanup'
fi

# macOS system conveniences
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# OrbStack shell integration
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
