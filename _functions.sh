# Shared helper functions for chezmoi install scripts (included via {{ include }})
# This file is prefixed with _ so chezmoi doesn't deploy it.

# ── Helpers ──────────────────────────────────────────────────────────

# Check if a command is available
is_installed() {
  command -v "$1" >/dev/null 2>&1
}

# ── OS detection ─────────────────────────────────────────────────────

is_macos()  { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux()  { [[ "$(uname -s)" == "Linux" ]]; }
is_windows() { [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; }

# ── Verdict helpers ──────────────────────────────────────────────────

ok()   { echo "✓ $1"; }
skip() { echo "ℹ $1 — skipping"; }
fail() { echo "✗ $1"; exit 1; }

# ── macOS (defer to Homebrew Bundle) ─────────────────────────────────

# Call this on macOS for tools that are in the Brewfile.
skip_on_macos() {
  if is_macos; then
    skip "$1 is managed via Homebrew Bundle (Brewfile) on macOS"
    exit 0
  fi
}

# ── Package manager dispatch ────────────────────────────────────────

try_apt() {
  if is_linux && command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
    echo "  → installing $1 via apt..."
    sudo apt-get update && sudo apt-get install -y "$1"
    return 0
  fi
  return 1
}

try_dnf() {
  if is_linux && command -v dnf >/dev/null 2>&1; then
    echo "  → installing $1 via dnf..."
    sudo dnf install -y "$1"
    return 0
  fi
  return 1
}

try_pacman() {
  if is_linux && command -v pacman >/dev/null 2>&1; then
    echo "  → installing $1 via pacman..."
    sudo pacman -S --noconfirm "$1"
    return 0
  fi
  return 1
}

try_cargo() {
  if command -v cargo >/dev/null 2>&1; then
    echo "  → installing $1 via cargo..."
    cargo install "$1" --locked
    return 0
  fi
  return 1
}

try_scoop() {
  if is_windows && command -v scoop >/dev/null 2>&1; then
    echo "  → installing $1 via scoop..."
    scoop install "$1"
    return 0
  fi
  return 1
}

try_winget() {
  if is_windows && command -v winget >/dev/null 2>&1; then
    echo "  → installing $1 via winget..."
    winget install "$1"
    return 0
  fi
  return 1
}

# Fallback: curl-based installer
try_curl_sh() {
  local url="$1"
  echo "  → installing via curl | sh..."
  curl -sS "$url" | sh -s -- --yes
}

# ── Main flow ────────────────────────────────────────────────────────

# Install a tool across platforms using package managers.
# Usage: install_tool <name> <brew_name> <apt_name> <dnf_name> <pacman_name> <cargo_name> <scoop_name> <winget_name> <curl_url>
#   name       - human-readable name (e.g. "Starship")
#   brew_name  - Homebrew formula name (used in Brewfile, so we skip on macOS)
#   apt_* etc  - package name for that manager
#   cargo_name - crate name for `cargo install`
#   scoop_name - scoop package name
#   winget_name - winget package name
#   curl_url   - URL for the curl | sh fallback installer
install_tool() {
  local name="$1"
  local brew_name="$2"
  local apt_name="$3"
  local dnf_name="$4"
  local pacman_name="$5"
  local cargo_name="$6"
  local scoop_name="$7"
  local winget_name="$8"
  local curl_url="$9"

  if is_installed "$brew_name"; then
    ok "$name already installed: $($brew_name --version 2>/dev/null | head -n1)"
    exit 0
  fi

  echo "Installing $name..."

  # macOS defers to Homebrew Bundle
  if is_macos; then
    skip "$name is managed via Homebrew Bundle (Brewfile) on macOS"
    exit 0
  fi

  # Try package managers in order
  try_apt "$apt_name" ||
    try_dnf "$dnf_name" ||
    try_pacman "$pacman_name" ||
    try_cargo "$cargo_name" ||
    try_scoop "$scoop_name" ||
    try_winget "$winget_name" ||
    try_curl_sh "$curl_url"

  # Verify
  if is_installed "$brew_name"; then
    ok "$name installed: $($brew_name --version 2>/dev/null | head -n1)"
  else
    fail "$name installation failed"
  fi
}
