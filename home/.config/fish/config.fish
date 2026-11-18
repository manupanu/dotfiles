# Main fish entrypoint. Environment lives in conf.d/, functions in functions/.
status is-interactive; or return

set -g fish_greeting

# General aliases
abbr -a c clear
if command -q eza
    alias ls 'eza --icons'
    alias ll 'eza -l --icons'
    alias la 'eza -la --icons'
end

set -l nprocs (sysctl -n hw.ncpu 2>/dev/null; or echo 2)
alias make "make -j$nprocs"
alias ninja "ninja -j$nprocs"
alias n "ninja -j$nprocs"

alias agy 'agy --dangerously-skip-permissions'
alias antigravity 'agy --dangerously-skip-permissions'

# macOS conveniences
if command -q brew
    alias update 'brew update && brew upgrade'
    alias cleanch 'brew cleanup'
end
alias flushdns 'sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles 'defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles 'defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Tool integrations
command -q mise; and mise activate fish | source
command -q fnm; and fnm env --use-on-cd --shell fish | source
command -q fzf; and fzf --fish | source
command -q copilot; and copilot completion fish | source
command -q zoxide; and zoxide init fish | source
command -q starship; and starship init fish | source
test -f ~/.orbstack/shell/init.fish; and source ~/.orbstack/shell/init.fish 2>/dev/null
