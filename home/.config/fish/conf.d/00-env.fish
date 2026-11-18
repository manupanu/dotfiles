# Login/environment setup shared by interactive and non-interactive fish.

if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

fish_add_path -g /opt/homebrew/opt/rustup/bin $HOME/.cargo/bin $HOME/.opencode/bin
fish_add_path -g $HOME/.local/bin $HOME/.cache/.bun/bin $HOME/.bun/bin
if test -d (brew --prefix 2>/dev/null; or echo /opt/homebrew)/opt/python/libexec/bin
    fish_add_path -g (brew --prefix)/opt/python/libexec/bin
end

if command -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else if command -q vim
    set -gx EDITOR vim
    set -gx VISUAL vim
end

set -gx PIPENV_VENV_IN_PROJECT 1

# Trust the installed Cato TLS-inspection CA in Node/Bun; keep verification enabled.
set -gx NODE_EXTRA_CA_CERTS $HOME/.config/certificates/cato-root.pem

# Point agent-aware tools at 1Password instead of macOS's default agent.
set -l op_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if test -S $op_sock
    if test -z "$SSH_AUTH_SOCK"; or string match -q '/var/run/com.apple.launchd.*/Listeners' -- $SSH_AUTH_SOCK
        set -gx SSH_AUTH_SOCK $op_sock
    end
end

# Readable man-page emphasis
set -gx LESS_TERMCAP_md (tput bold 2>/dev/null; tput setaf 2 2>/dev/null)
set -gx LESS_TERMCAP_me (tput sgr0 2>/dev/null)
