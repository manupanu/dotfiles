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

if [[ -f "$antidote_path/antidote.zsh" ]]; then
  # Rebuild bundle only when the plugin manifest changes
  if [[ ! "$zsh_plugins_static" -nt "$zsh_plugins_txt" ]]; then
    source "$antidote_path/antidote.zsh"
    antidote bundle <"$zsh_plugins_txt" >"$zsh_plugins_static"
  fi
  source "$zsh_plugins_static"
fi

unset zsh_dir zsh_plugins_txt zsh_plugins_static antidote_path
