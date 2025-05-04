"""
mdm.py (Manuels Dotfile Manager)

This script manages dotfiles by creating symbolic links based on a configuration
defined in a YAML file (links.yaml). It automatically detects the operating
system (Linux, macOS, Windows) and applies the appropriate links defined in
the configuration.

Features:
- Reads link configurations from links.yaml.
- Supports common links and OS-specific links (linux, macos, windows).
- Automatically creates necessary parent directories for target links.
- Checks for existing files or incorrect symlinks at the target location.
- Includes a dry-run mode to preview changes without modifying the filesystem.
- Requires Python 3 and the PyYAML library.
"""
import yaml
import os
import platform
import sys
from pathlib import Path

# --- Configuration ---
CONFIG_FILE = "links.yaml" # Name of the YAML configuration file

# --- Helper Functions ---

def get_os_type() -> str:
    """
    Determines the current operating system type ('linux', 'macos', 'windows', or 'unknown').

    Uses platform.system() and checks for common identifiers.

    Returns:
        str: The detected OS type as a lowercase string.
    """
    system = platform.system().lower()
    if "linux" in system: # Covers Linux distributions and WSL
        return "linux"
    elif system == "darwin":
        return "macos"
    elif system == "windows":
        return "windows"
    else:
        print(f"❓ Unknown OS detected: {platform.system()}")
        return "unknown"

def create_symlink(source: Path, target: Path, dry_run: bool = False):
    """
    Attempts to create a symbolic link from the source path to the target path.

    Handles:
    - Checking if the source file exists.
    - Creating parent directories for the target if they don't exist.
    - Checking if the target path already exists (as a file or incorrect symlink).
    - Printing informative messages about actions taken or skipped.
    - Handling potential OS-level errors during directory/link creation.

    Args:
        source (Path): The absolute path to the source file/directory in the dotfiles repo.
        target (Path): The absolute path to the target location in the home directory.
        dry_run (bool): If True, only print actions without modifying the filesystem.
    """
    # Ensure source and target paths are absolute and user-expanded
    source = source.resolve()
    target = target.expanduser() # Expand ~

    print(f"---\nProcessing Link Target: {target}")

    # 1. Check if source exists
    if not source.exists():
        print(f"⚠️ Source file/directory does not exist, skipping: {source}")
        return

    # 2. Ensure parent directory for the target exists
    target_dir = target.parent
    if not target_dir.exists():
        print(f"🔧 Creating parent directory: {target_dir}")
        if not dry_run:
            try:
                target_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                print(f"❌ Error creating directory {target_dir}: {e}")
                return # Cannot proceed if directory creation fails
    elif not target_dir.is_dir():
         # If the parent path exists but isn't a directory, we can't create the link inside it.
         print(f"❌ Target parent path exists but is not a directory: {target_dir}")
         return

    # 3. Check the target path status
    if target.is_symlink():
        # Target exists and is a symlink, check if it points to the correct source
        try:
            # os.readlink returns the path *as stored* in the link
            # We resolve both the link's target and the intended source for comparison
            current_link_target = Path(os.readlink(target))
            # If the link target is relative, resolve it relative to the link's parent dir
            if not current_link_target.is_absolute():
                current_link_target = (target.parent / current_link_target).resolve()
            else:
                 current_link_target = current_link_target.resolve()


            if current_link_target == source:
                print(f"✅ Link already exists and is correct: {target} -> {source}")
                return # Nothing to do
            else:
                print(f"⚠️ Target is a symlink but points elsewhere.")
                print(f"   Current: {target} -> {current_link_target}")
                print(f"   Desired: {target} -> {source}")
                print(f"   Skipping to avoid overwriting.")
                # Optional: Add logic here to remove incorrect link if desired (e.g., with a --force flag)
                return
        except OSError as e:
             # This might happen if the link is broken or permissions are wrong
             print(f"⚠️ Could not read existing symlink target {target}: {e}. Skipping.")
             return

    elif target.exists():
         # Target exists but is not a symlink (it's a regular file or directory)
         print(f"⚠️ Target already exists (and is not a symlink), skipping: {target}")
         # Optional: Add logic here to backup/remove existing file/dir if desired (e.g., with a --force flag)
         return

    # 4. Create the link
    print(f"🔗 Linking: {target} -> {source}")
    if not dry_run:
        try:
            # Create the symbolic link.
            # target_is_directory=source.is_dir() is crucial on Windows for directory links.
            # On Unix-like systems, it's often ignored or automatically handled.
            os.symlink(source, target, target_is_directory=source.is_dir())
            print(f"✅ Successfully linked: {target}")
        except OSError as e:
            print(f"❌ Error linking {target} -> {source}: {e}")
            # Provide specific advice for Windows permission issues
            if platform.system() == "Windows":
                print("ℹ️ Note: Creating symlinks on Windows often requires:")
                print("   - Running the script as Administrator OR")
                print("   - Enabling Developer Mode (Windows 10/11 Settings -> Privacy & security -> For developers)")
        except Exception as e:
             # Catch any other unexpected errors during linking
             print(f"❌ An unexpected error occurred during linking: {e}")

# --- Main Execution ---

def main(dry_run: bool = False):
    """
    Main function to load configuration and orchestrate the linking process.

    Steps:
    1. Determines the script's directory to find the config file.
    2. Loads and parses the links.yaml configuration.
    3. Determines the base directory for source files from the config.
    4. Detects the current operating system.
    5. Merges 'common' links and OS-specific links from the config.
    6. Iterates through the links and calls create_symlink for each.

    Args:
        dry_run (bool): If True, pass the dry-run flag to create_symlink.
    """
    if dry_run:
        print("💨 Performing a dry run. No actual changes will be made.")
    print(f"🚀 Starting mdm (Manuels Dotfile Manager) linking process...")

    # Determine paths relative to the script's location
    script_dir = Path(__file__).parent.resolve()
    config_path = script_dir / CONFIG_FILE

    # --- Load Configuration ---
    if not config_path.exists():
        print(f"❌ Error: Configuration file not found at {config_path}")
        sys.exit(1) # Exit if config is missing

    config = None
    try:
        print(f"📖 Reading configuration from: {config_path}")
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing YAML configuration file {config_path}: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading configuration file {config_path}: {e}")
        sys.exit(1)

    # Basic validation of loaded config
    if not isinstance(config, dict):
         print(f"❌ Error: Configuration file {config_path} does not contain a valid YAML dictionary (key-value pairs).")
         sys.exit(1)

    # Determine the base directory for source files (relative to the script dir)
    base_dir_name = config.get("base_dir", ".") # Default to current dir if not specified
    source_base_dir = (script_dir / base_dir_name).resolve()
    print(f"📂 Using source base directory: {source_base_dir}")

    # --- Determine Links to Create ---
    current_os = get_os_type()
    print(f"💻 Detected OS: {current_os}")

    links_to_create = {}
    # 1. Add common links
    common_links = config.get("common")
    if isinstance(common_links, dict):
        links_to_create.update(common_links)
    elif common_links is not None:
         # Warn if 'common' exists but isn't a dictionary
         print(f"⚠️ 'common' section in {CONFIG_FILE} is not a dictionary, skipping.")

    # 2. Add OS-specific links (overwriting common links if keys conflict)
    os_specific_links = None
    if current_os != "unknown":
        os_specific_links = config.get(current_os)
        if isinstance(os_specific_links, dict):
            links_to_create.update(os_specific_links) # Update merges dictionaries
        elif os_specific_links is not None:
             # Warn if OS-specific section exists but isn't a dictionary
             print(f"⚠️ '{current_os}' section in {CONFIG_FILE} is not a dictionary, skipping.")
    else:
        # Handle case where OS detection failed
        print("⚠️ Unknown OS detected, only applying 'common' links.")

    # --- Process Links ---
    if not links_to_create:
        print("🤷 No links defined in the configuration for this OS. Nothing to do.")
        return # Exit gracefully if no links are applicable

    print(f"\nProcessing {len(links_to_create)} link(s) defined in {CONFIG_FILE}:")
    link_count = 0
    for source_rel, target_str in links_to_create.items():
        link_count += 1
        print(f"\n[{link_count}/{len(links_to_create)}] -----")
        # Basic validation of link entries
        if not isinstance(source_rel, str) or not isinstance(target_str, str) or not source_rel or not target_str:
            print(f"⚠️ Skipping invalid entry in {CONFIG_FILE}: Source='{source_rel}', Target='{target_str}'")
            continue

        # Construct absolute source path and target path object
        source_path = source_base_dir / source_rel
        target_path = Path(target_str) # Pathlib handles '~' expansion later in create_symlink

        # Call the function to handle the actual linking logic
        create_symlink(source_path, target_path, dry_run)

    print("\n🏁 Dotfiles linking process finished.")

# --- Script Entry Point ---
if __name__ == "__main__":
    # Simple argument parsing for --dry-run or -n flag
    is_dry_run = "--dry-run" in sys.argv or "-n" in sys.argv

    # Check for PyYAML dependency before proceeding
    try:
        import yaml
    except ImportError:
        print("❌ Error: Required package 'PyYAML' not found.")
        print("ℹ️ Please install it, for example using pip:")
        print("   pip install PyYAML")
        sys.exit(1) # Exit if dependency is missing

    # Run the main logic
    main(dry_run=is_dry_run)
