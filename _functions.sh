# Shared helper functions for chezmoi install scripts.
# Prefixed with _ so chezmoi doesn't deploy it.

# ── OS detection ─────────────────────────────────────────────────────

is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux()  { [[ "$(uname -s)" == "Linux" ]]; }
is_windows() { [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN)$ ]]; }

# ── Verdict ───────────────────────────────────────────────────────────

ok()   { echo "✓ $1"; }
skip() { echo "ℹ $1 — skipping"; }
fail() { echo "✗ $1"; exit 1; }

# ── Package install ───────────────────────────────────────────────────

# macOS: tools are in the Brewfile, skip.
# Linux: try pacman → apt → dnf → cargo
# Windows: try scoop → winget
# Fallback: curl | sh
install_tool() {
  local name="$1"
  shift

  # Already installed?
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name already installed: $($name --version 2>/dev/null | head -1)"
    exit 0
  fi

  # macOS → Brewfile handles it
  if is_macos; then
    skip "$name is managed via Homebrew Bundle on macOS"
    exit 0
  fi

  echo "Installing $name..."

  if is_linux; then
    if command -v pacman >/dev/null 2>&1 && { [ -f /etc/arch-release ] || [ -f /etc/cachyos-release ] || grep -qs 'ID_LIKE=arch' /etc/os-release 2>/dev/null; }; then
      sudo pacman -S --noconfirm "$name" && { ok "$name installed"; return 0; }
    elif command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
      sudo apt-get update && sudo apt-get install -y "$name" && { ok "$name installed"; return 0; }
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y "$name" && { ok "$name installed"; return 0; }
    elif command -v cargo >/dev/null 2>&1; then
      cargo install "$name" --locked && { ok "$name installed"; return 0; }
    fi
  fi

  if is_windows; then
    if command -v scoop >/dev/null 2>&1; then
      scoop install "$name" && { ok "$name installed"; return 0; }
    elif command -v winget >/dev/null 2>&1; then
      winget install "$name" && { ok "$name installed"; return 0; }
    fi
  fi

  # curl fallback — last arg must be the URL
  if [[ $# -gt 0 ]]; then
    echo "  → installing via curl | sh..."
    curl -sS "$1" | sh -s -- --yes && { ok "$name installed"; return 0; }
  fi

  fail "$name installation failed"
}