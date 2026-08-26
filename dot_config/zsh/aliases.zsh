# General convenience aliases
alias c='clear'
alias n='ninja'

# Multi-core build aliases (Linux & macOS compatible)
_get_nprocs() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  elif command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null || echo 2
  else
    echo 2
  fi
}
alias make='make -j$(_get_nprocs)'
alias ninja='ninja -j$(_get_nprocs)'

# Yazi wrapper: `y` changes current directory to Yazi's last visited directory
y() {
  local tmp cwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

# Antigravity CLI
alias agy='agy --dangerously-skip-permissions'
alias antigravity='agy --dangerously-skip-permissions'
