# Antidote plugin manager setup
zsh_dir="${ZDOTDIR:-$HOME/.config/zsh}"
zsh_plugins_txt="$zsh_dir/plugins.txt"
zsh_plugins_static="$zsh_dir/.zsh_plugins.zsh"

# Locate or auto-install antidote
antidote_path="${zsh_dir}/.antidote"
if [[ ! -d "$antidote_path" && -d "$HOME/.antidote" ]]; then
  antidote_path="$HOME/.antidote"
elif [[ ! -d "$antidote_path" ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_path" 2>/dev/null
fi

_zsh_plugins_bundle_paths_exist() {
  local bundle_file="$1"
  local line target

  [[ -s "$bundle_file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ '^source "([^"]+)"$' ]]; then
      target="${(e)match[1]}"
      [[ -f "$target" ]] || return 1
    elif [[ "$line" =~ '^fpath\+=\( "([^"]+)" \)$' ]]; then
      target="${(e)match[1]}"
      [[ -d "$target" ]] || return 1
    fi
  done < "$bundle_file"
}

_zsh_plugins_bundle_is_current() {
  [[ -s "$zsh_plugins_static" && "$zsh_plugins_static" -nt "$zsh_plugins_txt" ]] &&
    _zsh_plugins_bundle_paths_exist "$zsh_plugins_static"
}

if [[ -f "$antidote_path/antidote.zsh" ]]; then
  if ! _zsh_plugins_bundle_is_current && source "$antidote_path/antidote.zsh"; then
    # Build beside the destination so a failed fetch never truncates the last bundle.
    zsh_plugins_tmp="$(mktemp "${zsh_plugins_static}.tmp.XXXXXX" 2>/dev/null)"
    if [[ -n "$zsh_plugins_tmp" ]] &&
      antidote bundle <"$zsh_plugins_txt" >"$zsh_plugins_tmp" &&
      _zsh_plugins_bundle_paths_exist "$zsh_plugins_tmp" &&
      mv -f "$zsh_plugins_tmp" "$zsh_plugins_static"; then
      zsh_plugins_tmp=""
    fi
    [[ -z "$zsh_plugins_tmp" ]] || rm -f "$zsh_plugins_tmp"
  fi

  if _zsh_plugins_bundle_paths_exist "$zsh_plugins_static"; then
    source "$zsh_plugins_static"
  else
    print -u2 "zsh: Antidote plugins unavailable; bundle rebuild failed"
  fi
else
  print -u2 "zsh: Antidote unavailable; plugins were not loaded"
fi

unfunction _zsh_plugins_bundle_paths_exist _zsh_plugins_bundle_is_current
unset zsh_dir zsh_plugins_txt zsh_plugins_static antidote_path zsh_plugins_tmp
