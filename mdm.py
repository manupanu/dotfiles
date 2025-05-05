#!/usr/bin/env python3
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
- Includes a dry-run mode (--dry-run, -n) to preview changes.
- Force mode (--force, -f) to overwrite existing files/links.
- Requires Python 3 and the PyYAML library.
"""
import os
import platform
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("❌ Error: Required package 'PyYAML' not found.")
    print("ℹ️ Please install it using:")
    print("   pip install PyYAML")
    sys.exit(1)

# Configuration
CONFIG_FILE = "mdm_conf.yaml"

def get_os_type() -> str:
    """
    Determines the current operating system type.

    Returns:
        str: Operating system identifier ('linux', 'macos', 'windows', or 'unknown').
    """
    system = platform.system().lower()
    if "linux" in system:  # Covers Linux distributions and WSL
        return "linux"
    elif system == "darwin":
        return "macos"
    elif system == "windows":
        return "windows"
    else:
        print(f"❓ Unknown OS detected: {platform.system()}")
        return "unknown"

def create_symlink(source: Path, target: Path, dry_run: bool = False, force: bool = False) -> None:
    """
    Creates a symbolic link from source to target.

    Args:
        source: Path to the source file/directory in the dotfiles repo.
        target: Path where the symlink should be created.
        dry_run: If True, only simulate and print actions without making changes.
        force: If True, overwrite existing files/links at the target location.
    """
    source = source.resolve()
    target = target.expanduser()

    print(f"\n---\nProcessing Link Target: {target}")

    if not source.exists():
        print(f"⚠️ Source does not exist, skipping: {source}")
        return

    target_dir = target.parent
    if not target_dir.exists():
        print(f"🔧 Creating directory: {target_dir}")
        if not dry_run:
            try:
                target_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                print(f"❌ Error creating directory {target_dir}: {e}")
                return
    elif not target_dir.is_dir():
        print(f"❌ Target parent exists but is not a directory: {target_dir}")
        return

    if target.is_symlink():
        try:
            current_link_target = Path(os.readlink(target))
            if not current_link_target.is_absolute():
                current_link_target = (target.parent / current_link_target).resolve()
            else:
                current_link_target = current_link_target.resolve()

            if current_link_target == source:
                print(f"✅ Link already exists and is correct: {target} -> {source}")
                return
            else:
                if force:
                    print(f"🔄 Replacing existing symlink:")
                    print(f"   Old: {target} -> {current_link_target}")
                    print(f"   New: {target} -> {source}")
                    if not dry_run:
                        target.unlink()
                else:
                    print(f"⚠️ Target is a symlink but points elsewhere:")
                    print(f"   Current: {target} -> {current_link_target}")
                    print(f"   Desired: {target} -> {source}")
                    print("   Use --force (-f) to overwrite")
                    return
        except OSError as e:
            print(f"⚠️ Could not read existing symlink {target}: {e}")
            if force and not dry_run:
                try:
                    target.unlink()
                except OSError as e:
                    print(f"❌ Error removing broken symlink: {e}")
                    return
            else:
                return
    elif target.exists():
        if force:
            print(f"🔄 Removing existing file/directory: {target}")
            if not dry_run:
                try:
                    if target.is_dir() and not target.is_symlink():
                        import shutil
                        shutil.rmtree(target)
                    else:
                        target.unlink()
                except OSError as e:
                    print(f"❌ Error removing existing target: {e}")
                    return
        else:
            print(f"⚠️ Target exists (not a symlink), skipping: {target}")
            print("   Use --force (-f) to overwrite")
            return

    print(f"🔗 Creating link: {target} -> {source}")
    if not dry_run:
        try:
            os.symlink(source, target, target_is_directory=source.is_dir())
            print(f"✅ Successfully linked: {target}")
        except OSError as e:
            print(f"❌ Error creating link: {e}")
            if platform.system() == "Windows":
                print("ℹ️ Note: Creating symlinks on Windows requires:")
                print("   - Administrator privileges OR")
                print("   - Developer Mode enabled")
        except Exception as e:
            print(f"❌ Unexpected error: {e}")

def copy_item(source: Path, target: Path, dry_run: bool = False, force: bool = False) -> None:
    """
    Copies a file or directory from source to target.
    """
    import shutil
    source = source.resolve()
    target = target.expanduser()
    print(f"\n---\nCopying to Target: {target}")
    if not source.exists():
        print(f"⚠️ Source does not exist, skipping: {source}")
        return
    target_dir = target.parent
    if not target_dir.exists():
        print(f"🔧 Creating directory: {target_dir}")
        if not dry_run:
            try:
                target_dir.mkdir(parents=True, exist_ok=True)
            except OSError as e:
                print(f"❌ Error creating directory {target_dir}: {e}")
                return
    elif not target_dir.is_dir():
        print(f"❌ Target parent exists but is not a directory: {target_dir}")
        return
    if target.exists():
        if force:
            print(f"🔄 Removing existing file/directory: {target}")
            if not dry_run:
                try:
                    if target.is_dir() and not target.is_symlink():
                        shutil.rmtree(target)
                    else:
                        target.unlink()
                except OSError as e:
                    print(f"❌ Error removing existing target: {e}")
                    return
        else:
            print(f"⚠️ Target exists, skipping: {target}")
            print("   Use --force (-f) to overwrite")
            return
    print(f"📋 Copying: {source} -> {target}")
    if not dry_run:
        try:
            if source.is_dir():
                shutil.copytree(source, target)
            else:
                shutil.copy2(source, target)
            print(f"✅ Successfully copied: {target}")
        except Exception as e:
            print(f"❌ Error copying: {e}")

def exec_script(source: Path, args=None, dry_run: bool = False) -> None:
    """
    Executes a script with optional arguments.
    Uses bash for Linux/macOS, PowerShell for Windows.
    """
    import subprocess
    source = source.resolve()
    if not source.exists():
        print(f"⚠️ Script does not exist, skipping: {source}")
        return
    if args is None:
        args = []
    print(f"\n---\nExecuting script: {source} {' '.join(map(str, args))}")
    if dry_run:
        print(f"💨 Dry run: would execute {source} {' '.join(map(str, args))}")
        return
    if platform.system().lower() == "windows":
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(source)] + list(map(str, args))
    else:
        cmd = ["bash", str(source)] + list(map(str, args))
    try:
        result = subprocess.run(cmd, check=True)
        print(f"✅ Script executed with exit code {result.returncode}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Script failed with exit code {e.returncode}")
    except Exception as e:
        print(f"❌ Error executing script: {e}")

def main(dry_run: bool = False, force: bool = False) -> None:
    """
    Main function that orchestrates the dotfile linking process.
    
    Args:
        dry_run: If True, simulate actions without making changes.
        force: If True, overwrite existing files/links.
    """
    if dry_run:
        print("💨 Dry run mode - no changes will be made")
    if force:
        print("⚠️ Force mode - existing files/links will be overwritten")
    print("🚀 Starting mdm (Manuels Dotfile Manager)")

    script_dir = Path(__file__).parent.resolve()
    config_path = script_dir / CONFIG_FILE

    if not config_path.exists():
        print(f"❌ Configuration file not found: {config_path}")
        sys.exit(1)

    try:
        print(f"📖 Reading configuration from: {config_path}")
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing {CONFIG_FILE}: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading {CONFIG_FILE}: {e}")
        sys.exit(1)

    if not isinstance(config, dict):
        print(f"❌ Invalid configuration format in {CONFIG_FILE}")
        sys.exit(1)

    base_dir_name = config.get("base_dir", ".")
    source_base_dir = (script_dir / base_dir_name).resolve()
    print(f"📂 Source directory: {source_base_dir}")

    current_os = get_os_type()
    print(f"💻 Detected OS: {current_os}")

    links_to_create = {}
    
    common_links = config.get("common", {})
    if isinstance(common_links, dict):
        links_to_create.update(common_links)
    else:
        print("⚠️ Invalid 'common' section in config")

    if current_os != "unknown":
        os_links = config.get(current_os, {})
        if isinstance(os_links, dict):
            links_to_create.update(os_links)
        else:
            print(f"⚠️ Invalid '{current_os}' section in config")
    else:
        print("⚠️ Unknown OS - using only common links")

    import socket
    hostname = socket.gethostname()
    host_section = f"host-{hostname}"
    if host_section in config and isinstance(config[host_section], dict):
        print(f"\U0001F4BB Detected host section: {host_section}")
        links_to_create.update(config[host_section])

    if not links_to_create:
        print("🤷 No links defined for this configuration")
        return

    print(f"\nProcessing {len(links_to_create)} links:")
    for idx, (source_rel, entry) in enumerate(links_to_create.items(), 1):
        print(f"\n[{idx}/{len(links_to_create)}] -----")
        # Support both string (legacy) and dict (new)
        if isinstance(entry, str):
            action_type = "link"
            target_str = entry
            args = None
        elif isinstance(entry, dict):
            action_type = entry.get("type", "link")
            target_str = entry.get("target")
            args = entry.get("args")
        else:
            print(f"⚠️ Invalid link entry: {source_rel} -> {entry}")
            continue
        if not isinstance(source_rel, str) or not isinstance(target_str, str):
            print(f"⚠️ Invalid link entry: {source_rel} -> {target_str}")
            continue
        source_path = source_base_dir / source_rel
        target_path = Path(target_str)
        if action_type == "link":
            create_symlink(source_path, target_path, dry_run, force)
        elif action_type == "copy":
            copy_item(source_path, target_path, dry_run, force)
        elif action_type == "exec":
            exec_script(source_path, args, dry_run)
        else:
            print(f"⚠️ Unknown action type '{action_type}' for {source_rel}")

    print("\n🏁 Dotfiles linking process complete")

if __name__ == "__main__":
    main(
        dry_run=("--dry-run" in sys.argv or "-n" in sys.argv),
        force=("--force" in sys.argv or "-f" in sys.argv)
    )
