#!/bin/bash

# --- OS Detection ---
CURRENT_OS=""
OS_NAME=$(uname -s)
case "$OS_NAME" in
    Linux*)  CURRENT_OS="linux";;
    Darwin*) CURRENT_OS="macos";;
    *)       echo "Warning: Unsupported OS '$OS_NAME' for install.sh"; CURRENT_OS="unknown";;
esac
# --- End OS Detection ---

# Get the directory where the script is located (repo root)
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$REPO_ROOT/links.conf"

echo "Starting dotfiles installation for OS: $CURRENT_OS ..."

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Read the config file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # --- OS Filtering Logic ---
    target_oses="all" # Default to all
    config_part="$line"

    # Check if line contains an OS specifier [...] using regex
    if [[ "$line" =~ ^(.*)[[:space:]]*\[([^\]]+)\][[:space:]]*$ ]]; then
        config_part="${BASH_REMATCH[1]}" # Part before brackets
        os_specifier="${BASH_REMATCH[2]}" # Content inside brackets
        target_oses=$(echo "$os_specifier" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]') # Remove spaces, lowercase
    fi

    # Check if the current OS matches the target OSes for this line
    apply_line=false
    if [[ "$target_oses" == "all" ]]; then
        apply_line=true
    else
        # Check if CURRENT_OS is in the comma-separated list
        if [[ ",$target_oses," == *",$CURRENT_OS,"* ]]; then
             apply_line=true
        fi
    fi

    if ! $apply_line; then
        # echo "Skipping line for $CURRENT_OS: $line" # Optional debug
        continue # Skip this line if OS doesn't match
    fi
    # --- End OS Filtering Logic ---

    # Split the config_part into source and target at the first ':'
    repo_path="${config_part%%:*}"
    target_path="${config_part#*:}"

    # Trim whitespace (optional but good practice)
    repo_path=$(echo "$repo_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    target_path=$(echo "$target_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if split was successful (simple check)
    if [ -z "$repo_path" ] || [ -z "$target_path" ] || [ "$repo_path" == "$config_part" ]; then
        echo "Warning: Skipping invalid line format: $line"
        continue
    fi

    # Construct absolute source path
    abs_source_path="$REPO_ROOT/$repo_path"

    # Expand ~ in target path
    eval "expanded_target_path=\"$target_path\"" # Use eval carefully for tilde expansion, quoted

    # Get the target directory
    target_dir=$(dirname "$expanded_target_path")

    # Check if source file exists
    if [ ! -e "$abs_source_path" ]; then
        echo "Warning: Source file not found, skipping: $abs_source_path (from line: $line)"
        continue
    fi

    # Create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        echo "Creating directory: $target_dir"
        mkdir -p "$target_dir"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create directory $target_dir. Skipping."
            continue
        fi
    fi

    # Create symbolic link (force overwrite, no dereference)
    echo "Linking $expanded_target_path -> $abs_source_path"
    ln -sfn "$abs_source_path" "$expanded_target_path"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to link $expanded_target_path. Check permissions."
    fi

done < "$CONFIG_FILE"

echo "Dotfiles installation complete."
exit 0 