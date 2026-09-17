# General convenience aliases
alias c='clear'

# eza (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
fi

# Multi-core build aliases (Linux & macOS compatible)
() {
  local nprocs=2
  if command -v nproc >/dev/null 2>&1; then
    nprocs=$(nproc)
  elif command -v sysctl >/dev/null 2>&1; then
    nprocs=$(sysctl -n hw.ncpu 2>/dev/null || echo 2)
  fi
  alias make="make -j${nprocs}"
  alias ninja="ninja -j${nprocs}"
  alias n="ninja -j${nprocs}"
}

# Yazi wrapper: `y` changes current directory to Yazi's last visited directory
y() {
  local tmp cwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
}

# Antigravity CLI
alias agy='agy --dangerously-skip-permissions'
alias antigravity='agy --dangerously-skip-permissions'
