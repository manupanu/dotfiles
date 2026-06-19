#!/bin/sh
set -eu

SOURCE_DIR="${1:-/home/manuel/.dotfiles}"

validate_template_for_os() {
  os_name="$1"
  template_file="$2"

  chezmoi --source="$SOURCE_DIR" execute-template --file --override-data "{\"targetOS\":\"$os_name\"}" "$template_file" >/dev/null
}

echo "Validating templates for linux/darwin/windows..."
for os_name in linux darwin windows; do
  validate_template_for_os "$os_name" "$SOURCE_DIR/dot_gitconfig.tmpl"
  validate_template_for_os "$os_name" "$SOURCE_DIR/dot_zsh/dot_zshrc.tmpl"
  validate_template_for_os "$os_name" "$SOURCE_DIR/dot_zsh/dot_zprofile.tmpl"
  validate_template_for_os "$os_name" "$SOURCE_DIR/dot_zsh/aliases.zsh.tmpl"
  validate_template_for_os "$os_name" "$SOURCE_DIR/dot_config/ghostty/config.tmpl"
  validate_template_for_os "$os_name" "$SOURCE_DIR/.chezmoiignore.tmpl"
done

echo "Template validation passed."
