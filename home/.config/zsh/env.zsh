# User-installed executables & paths
export PATH="$HOME/.local/bin:$HOME/.cache/.bun/bin:$HOME/.bun/bin:$PATH"

# Preferred editor
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
fi

# Rust & Cargo
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# fast node version manager
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# macOS Homebrew path support
if [[ "$OSTYPE" == darwin* ]]; then
  # Trust the installed Cato TLS-inspection CA in Node/Bun; keep verification enabled.
  export NODE_EXTRA_CA_CERTS="$HOME/.config/certificates/cato-root.pem"

  # Point agent-aware tools at 1Password instead of macOS's default agent.
  _1password_ssh_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [[ -S "$_1password_ssh_sock" && ( -z "$SSH_AUTH_SOCK" || "$SSH_AUTH_SOCK" == /var/run/com.apple.launchd.*/Listeners ) ]]; then
    export SSH_AUTH_SOCK="$_1password_ssh_sock"
  fi
  unset _1password_ssh_sock

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Homebrew Python unversioned symlinks (python -> python3)
  if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/python/libexec/bin" ]]; then
    export PATH="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/python/libexec/bin:$PATH"
  fi
  export PIPENV_VENV_IN_PROJECT=1
fi

# Readable man-page emphasis
export LESS_TERMCAP_md="$(tput bold 2>/dev/null; tput setaf 2 2>/dev/null)"
export LESS_TERMCAP_me="$(tput sgr0 2>/dev/null)"
