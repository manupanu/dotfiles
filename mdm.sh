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

# Global flag for Dry Run mode
DRY_RUN=false

# --- Function Definitions ---

manage_dotfiles() {
    echo "--- Managing Dotfiles ---"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE"
        return 1
    fi

    local line repo_path target_path abs_source_path expanded_target_path target_dir
    local target_oses config_part os_specifier apply_line

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
            if ! $DRY_RUN; then
                mkdir -p "$target_dir"
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to create directory $target_dir. Skipping." >&2
                    continue
                fi
            else
                echo "DRY RUN: Would create directory $target_dir"
            fi
        fi

        # Create symbolic link (force overwrite, no dereference)
        echo "Linking $expanded_target_path -> $abs_source_path"
        if ! $DRY_RUN; then
            ln -sfn "$abs_source_path" "$expanded_target_path"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to link $expanded_target_path. Check permissions." >&2
            fi
        else
            echo "DRY RUN: Would link $expanded_target_path -> $abs_source_path"
        fi

    done < "$CONFIG_FILE"
    echo "Dotfiles management complete."
}

install_software() {
    echo "--- Installing Software ---"
    local software_list package

    if [[ "$CURRENT_OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew (brew) not found. Please install it first."
            return 1
        fi
        software_list="$REPO_ROOT/modules/macos/software.list"
        if [ ! -f "$software_list" ]; then
            echo "Warning: Software list not found: $software_list"
            return 0 # Not an error, just nothing to install
        fi
        echo "Updating Homebrew..."
        if ! $DRY_RUN; then brew update; else echo "DRY RUN: Would run brew update"; fi
        echo "Installing packages from $software_list..."
        while IFS= read -r package || [[ -n "$package" ]]; do
            [[ -z "$package" || "$package" =~ ^# ]] && continue
            echo "Installing $package..."
            if ! $DRY_RUN; then brew install "$package"; else echo "DRY RUN: Would install brew package '$package'"; fi
        done < "$software_list"

    elif [[ "$CURRENT_OS" == "linux" ]]; then
        local pkg_manager=""
        if command -v apt &> /dev/null; then
            pkg_manager="apt"
            software_list="$REPO_ROOT/modules/linux/apt.list"
        elif command -v pacman &> /dev/null; then
            pkg_manager="pacman"
            software_list="$REPO_ROOT/modules/linux/pacman.list"
        else
            echo "Error: Neither apt nor pacman found. Cannot install software."
            return 1
        fi

        if [ ! -f "$software_list" ]; then
            echo "Warning: Software list not found: $software_list"
            return 0 # Not an error, just nothing to install
        fi

        echo "Updating package manager ($pkg_manager)..."
        if [[ "$pkg_manager" == "apt" ]]; then
            if ! $DRY_RUN; then sudo apt update; else echo "DRY RUN: Would run sudo apt update"; fi
        elif [[ "$pkg_manager" == "pacman" ]]; then
            if ! $DRY_RUN; then sudo pacman -Syu --noconfirm; else echo "DRY RUN: Would run sudo pacman -Syu --noconfirm"; fi
        fi

        echo "Installing packages from $software_list..."
        while IFS= read -r package || [[ -n "$package" ]]; do
            [[ -z "$package" || "$package" =~ ^# ]] && continue
            echo "Installing $package..."
            if [[ "$pkg_manager" == "apt" ]]; then
                if ! $DRY_RUN; then sudo apt install -y "$package"; else echo "DRY RUN: Would install apt package '$package'"; fi
            elif [[ "$pkg_manager" == "pacman" ]]; then
                if ! $DRY_RUN; then sudo pacman -S --noconfirm "$package"; else echo "DRY RUN: Would install pacman package '$package'"; fi
            fi
        done < "$software_list"
    else
        echo "Software installation not supported on OS: $CURRENT_OS"
        return 1
    fi
    echo "Software installation complete."
}

install_fonts() {
    echo "--- Installing Fonts ---"
    local font_source_dir="$REPO_ROOT/modules/common/fonts"
    local font_target_dir=""

    if [ ! -d "$font_source_dir" ]; then
        echo "Error: Font source directory not found: $font_source_dir"
        return 1
    fi

    if [[ "$CURRENT_OS" == "macos" ]]; then
        font_target_dir="$HOME/Library/Fonts"
    elif [[ "$CURRENT_OS" == "linux" ]]; then
        font_target_dir="$HOME/.local/share/fonts"
    else
        echo "Font installation not supported on OS: $CURRENT_OS"
        return 1
    fi

    echo "Ensuring font directory exists: $font_target_dir"
    if ! $DRY_RUN; then mkdir -p "$font_target_dir"; else echo "DRY RUN: Would ensure font directory exists: $font_target_dir"; fi

    echo "Copying fonts from $font_source_dir to $font_target_dir..."
    # Use cp -a to preserve attributes if possible, overwrite existing
    if ! $DRY_RUN; then
        cp -f "$font_source_dir"/* "$font_target_dir/"
        if [ $? -ne 0 ]; then
           echo "Error: Failed to copy fonts." >&2
           # Decide if this is fatal? Probably not.
        fi
    else
         # Simulate copying for dry run message
         for f in "$font_source_dir"/*; do
             echo "DRY RUN: Would copy $(basename "$f") to $font_target_dir/"
         done
    fi

    if [[ "$CURRENT_OS" == "linux" ]]; then
        echo "Updating font cache..."
        if command -v fc-cache &> /dev/null; then
            if ! $DRY_RUN; then fc-cache -fv; else echo "DRY RUN: Would run fc-cache -fv"; fi
        else
            echo "Warning: fc-cache command not found. Font cache not updated."
        fi
    fi
    echo "Font installation complete."
}

add_dotfile() {
    echo "--- Adding Dotfile ---"
    local source_path="$1"
    local repo_path="$2"
    local abs_repo_dest_path repo_dest_dir copy_action
    local normalized_target_path normalized_repo_path new_line

    # Validate arguments (basic checks)
    if [ -z "$source_path" ] || [ -z "$repo_path" ]; then
        echo "Error: For the 'add' task, both source path (-s) and repo path (-r) arguments are required." >&2
        return 1
    fi
    if [ ! -e "$source_path" ]; then
        echo "Error: Source path does not exist: $source_path" >&2
        return 1
    fi
    # Basic check to prevent absolute paths or parent directory traversal in repo path
    if [[ "$repo_path" == /* || "$repo_path" == *..* || "$repo_path" == *:* ]]; then
        echo "Error: Repo path '$repo_path' should be a relative path within the repo, without leading slashes, colons, or '..'." >&2
        return 1
    fi

    # Construct full destination path in the repo
    abs_repo_dest_path="$REPO_ROOT/$repo_path"
    repo_dest_dir=$(dirname "$abs_repo_dest_path")

    # Create parent directories in repo if they don't exist
    if [ ! -d "$repo_dest_dir" ]; then
        echo "Creating repository directory: $repo_dest_dir"
        if ! $DRY_RUN; then
            mkdir -p "$repo_dest_dir"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create repository directory $repo_dest_dir." >&2
                return 1
            fi
        else
            echo "DRY RUN: Would create repository directory $repo_dest_dir"
        fi
    fi

    # Copy the source file/directory to the repo
    copy_action="Copying file"
    if [ -d "$source_path" ]; then
        copy_action="Copying directory"
    fi
    echo "$copy_action from '$source_path' to '$abs_repo_dest_path'"
    if ! $DRY_RUN; then
        cp -r "$source_path" "$abs_repo_dest_path"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to copy to repository path $abs_repo_dest_path." >&2
            return 1
        fi
    else
        echo "DRY RUN: Would $copy_action from '$source_path' to '$abs_repo_dest_path'"
    fi

    # Normalize the original source path for links.conf (replace $HOME with ~)
    # Using parameter expansion for robust replacement
    normalized_target_path="${source_path/#$HOME/\~}"
    if [ "$normalized_target_path" == "$source_path" ]; then
        # Path didn't start with $HOME, warn and use absolute path
        echo "Warning: Source path '$source_path' does not start with the home directory ('$HOME'). Storing absolute path in links.conf." >&2
    fi

    # Append the entry to links.conf
    normalized_repo_path="$repo_path" # Already relative
    new_line="$normalized_repo_path:$normalized_target_path [all]" # Defaulting to [all] OS

    echo "Adding entry to $CONFIG_FILE: $new_line"

    if ! $DRY_RUN; then
        # Check if the file ends with a newline, add one if not (optional, for cleaner appending)
        if [ -s "$CONFIG_FILE" ] && [ "$(tail -c 1 "$CONFIG_FILE")" != "" ]; then
            echo "" >> "$CONFIG_FILE"
        fi

        echo "$new_line" >> "$CONFIG_FILE"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to update $CONFIG_FILE." >&2
            # Consider attempting to revert the file copy here? For now, just error out.
            return 1
        fi
    else
         echo "DRY RUN: Would add line '$new_line' to $CONFIG_FILE"
    fi

    echo "Dotfile '$source_path' added successfully."
    echo "You may want to manually edit '$CONFIG_FILE' to adjust OS specificity (currently '[all]')."
    return 0
}

update_software() {
    echo "--- Updating Software ---"
    local pkg_manager=""

    if [[ "$CURRENT_OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew (brew) not found." >&2
            return 1
        fi
        echo "Updating Homebrew and upgrading packages..."
        if ! $DRY_RUN; then
             brew update && brew upgrade
        else
             echo "DRY RUN: Would run 'brew update && brew upgrade'"
        fi

    elif [[ "$CURRENT_OS" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            pkg_manager="apt"
        elif command -v pacman &> /dev/null; then
            pkg_manager="pacman"
        else
            echo "Error: Neither apt nor pacman found. Cannot update software." >&2
            return 1
        fi

        echo "Updating package manager ($pkg_manager) and upgrading packages..."
        echo "This may require sudo privileges."
        if [[ "$pkg_manager" == "apt" ]]; then
            if ! $DRY_RUN; then
                 sudo apt update && sudo apt upgrade -y
            else
                 echo "DRY RUN: Would run 'sudo apt update && sudo apt upgrade -y'"
            fi
        elif [[ "$pkg_manager" == "pacman" ]]; then
             if ! $DRY_RUN; then
                  sudo pacman -Syu --noconfirm
             else
                  echo "DRY RUN: Would run 'sudo pacman -Syu --noconfirm'"
             fi
        fi
    else
        echo "Software update not supported on OS: $CURRENT_OS"
        return 1 # Indicate unsupported OS
    fi
    echo "Software update process finished."
}

# --- Argument Parsing ---
TASK="all" # Default task
SOURCE_PATH=""
REPO_PATH=""

# Use getopts for better argument handling
while getopts ":t:s:r:n" opt; do
  case $opt in
    t) TASK="$OPTARG" ;;
    s) SOURCE_PATH="$OPTARG" ;;
    r) REPO_PATH="$OPTARG" ;;
    n) DRY_RUN=true ;; # Set Dry Run flag
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

shift $((OPTIND -1))

# Validate Task
if [[ "$TASK" != "all" && "$TASK" != "dotfiles" && "$TASK" != "software" && "$TASK" != "fonts" && "$TASK" != "add" && "$TASK" != "update" ]]; then
    echo "Error: Invalid task specified: '$TASK'." >&2
    echo "Usage: $0 [-t <task>] [-n] [-s <source_path> -r <repo_path>]"
    echo "Available tasks: dotfiles, software, fonts, add, update, all (default)"
    echo "Options for 'add' task: -s /path/to/your/file -r relative/repo/path"
    echo "Option -n enables Dry Run mode."
    exit 1
fi

# Validate arguments for 'add' task
if [[ "$TASK" == "add" ]] && ( [ -z "$SOURCE_PATH" ] || [ -z "$REPO_PATH" ] ); then
     echo "Error: For task 'add', both -s <source_path> and -r <repo_path> must be provided." >&2
     exit 1
fi

# --- Main Execution ---
echo "Starting installation for OS: $CURRENT_OS with task: $TASK ..."

if [[ "$CURRENT_OS" == "unknown" ]]; then
    echo "Exiting due to unsupported OS."
    exit 1
fi

if $DRY_RUN; then
    echo "*** DRY RUN MODE ENABLED ***" >&2 # Output to stderr to avoid mixing with potential command output
fi

error_occurred=false

if [[ "$TASK" == "all" || "$TASK" == "dotfiles" ]]; then
    manage_dotfiles || error_occurred=true
fi

if [[ "$TASK" == "all" || "$TASK" == "software" ]]; then
    install_software || error_occurred=true
fi

if [[ "$TASK" == "all" || "$TASK" == "fonts" ]]; then
    install_fonts || error_occurred=true
fi

if [[ "$TASK" == "add" ]]; then
    add_dotfile "$SOURCE_PATH" "$REPO_PATH" || error_occurred=true
fi

if [[ "$TASK" == "update" ]]; then # Added update task execution
    update_software || error_occurred=true
fi

echo "--- Installation finished ---"
if $error_occurred; then
    echo "One or more tasks encountered errors."
    exit 1
else
    echo "All requested tasks completed successfully."
    exit 0
fi 