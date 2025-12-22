import os
import sys
import json
import shutil
import socket
import subprocess
import argparse
from pathlib import Path

# Global state for summary and flags
SUMMARY = {"modules": 0, "links": 0, "copied": 0, "packages": 0, "errors": []}
ARGS = None

def get_platform():
    if sys.platform == "win32": return "win32"
    if sys.platform == "darwin": return "darwin"
    return "linux"

def run_cmd(cmd, sudo=False):
    if ARGS and ARGS.dry_run:
        print(f"[DRY-RUN] -> Would run: {' '.join(cmd)}")
        return True
    
    if sudo and get_platform() != "win32":
        cmd = ["sudo"] + cmd
    print(f"-> Running: {' '.join(cmd)}")
    try:
        subprocess.check_call(cmd)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        SUMMARY["errors"].append(f"Command failed: {' '.join(cmd)}")
        return False

def is_installed(pkg):
    plat = get_platform()
    if plat == "win32":
        try:
            result = subprocess.run(["winget", "list", "--exact", pkg], capture_output=True, text=True)
            return result.returncode == 0
        except Exception: return False
    elif plat == "darwin":
        try:
            # brew list returns 0 if installed, non-zero if not
            result = subprocess.run(["brew", "list", pkg], capture_output=True)
            return result.returncode == 0
        except Exception: return False
    elif plat == "linux":
        try:
            result = subprocess.run(["dpkg", "-s", pkg], capture_output=True)
            return result.returncode == 0
        except Exception: return False
    return False

def resolve_contextual_config(config, hostname):
    plat = get_platform()
    resolved = []
    
    if not isinstance(config, dict):
        return resolved

    # Handle old-style platform-only dict for packages
    special_keys = {"all", "platforms", "hostnames"}
    if not any(k in config for k in special_keys):
        if plat in config:
            resolved.append(config[plat])
        return resolved

    if "all" in config:
        resolved.append(config["all"])
        
    if "platforms" in config:
        plat_cfg = config["platforms"]
        matched = False
        for plat_key, plat_val in plat_cfg.items():
            if plat_key == "default": continue
            if plat in [p.strip() for p in plat_key.split(",")]:
                matched = True
                resolved.append(plat_val)
        if not matched and "default" in plat_cfg:
            resolved.append(plat_cfg["default"])
            
    if "hostnames" in config:
        host_cfg = config["hostnames"]
        matched = False
        for host_key, host_val in host_cfg.items():
            if host_key == "default": continue
            if hostname in [h.strip() for h in host_key.split(",")]:
                matched = True
                resolved.append(host_val)
        if not matched and "default" in host_cfg:
            resolved.append(host_cfg["default"])
            
    return resolved

def install_packages(pkgs):
    if not pkgs: return
    
    to_install = []
    for pkg in pkgs:
        if is_installed(pkg):
            print(f"Package {pkg} already installed.")
        else:
            to_install.append(pkg)
            
    if not to_install: return
    
    plat = get_platform()
    if plat == "darwin":
        run_cmd(["brew", "install"] + to_install)
    elif plat == "linux":
        run_cmd(["apt-get", "install", "-y"] + to_install, sudo=True)
    elif plat == "win32":
        for pkg in to_install:
            run_cmd(["winget", "install", "--exact", pkg])
    
    SUMMARY["packages"] += len(to_install)

def ensure_backup(dst):
    if ARGS and ARGS.dry_run:
        if dst.exists() or dst.is_symlink():
            print(f"[DRY-RUN] -> Would backup {dst}")
        return

    if dst.exists() or dst.is_symlink():
        backup = dst.parent / (dst.name + ".bak")
        print(f"Backing up {dst} to {backup}")
        if backup.exists():
            if backup.is_dir(): shutil.rmtree(backup)
            else: os.remove(backup)
        shutil.move(str(dst), str(backup))

def setup_symlink(src, dst):
    dst = Path(dst).expanduser().resolve()
    src = Path(src).resolve()
    
    if not src.exists():
        err = f"Source missing: {src}"
        print(err)
        SUMMARY["errors"].append(err)
        return

    if dst.exists() or dst.is_symlink():
        try:
            if dst.is_symlink() and Path(os.readlink(dst)).resolve() == src:
                print(f"Checked: {dst} already linked.")
                return
        except OSError:
            pass
        
        ensure_backup(dst)

    if ARGS and ARGS.dry_run:
        print(f"[DRY-RUN] -> Would link: {dst} -> {src}")
        SUMMARY["links"] += 1
        return

    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        if get_platform() == "win32":
            os.symlink(src, dst, target_is_directory=src.is_dir())
        else:
            os.symlink(src, dst)
        print(f"Linked: {dst} -> {src}")
        SUMMARY["links"] += 1
    except OSError as e:
        err = f"Failed to link {dst}: {e}"
        print(err)
        SUMMARY["errors"].append(err)

def setup_copy(src, dst):
    dst = Path(dst).expanduser().resolve()
    src = Path(src).resolve()
    
    if not src.exists():
        err = f"Source missing: {src}"
        print(err)
        SUMMARY["errors"].append(err)
        return

    ensure_backup(dst)

    if ARGS and ARGS.dry_run:
        print(f"[DRY-RUN] -> Would copy: {dst} <- {src}")
        SUMMARY["copied"] += 1
        return

    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst)
    else:
        shutil.copy2(src, dst)
    print(f"Copied: {dst} <- {src}")
    SUMMARY["copied"] += 1

def process_links(links_dict, module_dir, hostname, action_fn):
    for item in resolve_contextual_config(links_dict, hostname):
        if isinstance(item, dict):
            for src, dst in item.items():
                action_fn(module_dir / src, dst)

def main():
    global ARGS
    parser = argparse.ArgumentParser(description="Dotfiles Manager")
    parser.add_argument("-d", "--dry-run", action="store_true", help="Show what would be done without making changes")
    ARGS = parser.parse_args()

    hostname = socket.gethostname()
    print(f"Hostname: {hostname}")
    root = Path(__file__).parent.resolve()
    modules_dir = root / "modules"
    
    if not modules_dir.exists():
        print("No modules directory found.")
        return

    all_packages = []
    modules_to_process = []

    # First pass: collect modules and packages
    for module_path in modules_dir.glob("**/module.json"):
        with open(module_path) as f:
            config = json.load(f)
        
        name = config.get('name', 'unknown')
        if "platforms" in config and get_platform() not in config["platforms"]:
            print(f"Skipping Module: {name} (Platform mismatch)")
            continue
            
        if "hostnames" in config:
            allowed_hosts = config["hostnames"]
            if isinstance(allowed_hosts, str):
                allowed_hosts = [h.strip() for h in allowed_hosts.split(",")]
            if hostname not in allowed_hosts:
                print(f"Skipping Module: {name} (Hostname mismatch)")
                continue

        modules_to_process.append((module_path, config))
        
        if "packages" in config:
            for item in resolve_contextual_config(config["packages"], hostname):
                if isinstance(item, list):
                    all_packages.extend(item)

    # Install all packages at once
    if all_packages:
        print("\n--- Installing Packages ---")
        install_packages(list(dict.fromkeys(all_packages))) # unique packages

    # Second pass: process links and copies
    for module_path, config in modules_to_process:
        print(f"\n--- Processing Module: {config.get('name', 'unknown')} ---")
        SUMMARY["modules"] += 1
        
        if "links" in config:
            process_links(config["links"], module_path.parent, hostname, setup_symlink)
        
        if "copy" in config:
            process_links(config["copy"], module_path.parent, hostname, setup_copy)

    # Summary report
    print("\n" + "="*30)
    print("      SUMMARY REPORT")
    print("="*30)
    print(f"Modules processed:  {SUMMARY['modules']}")
    print(f"Packages installed: {SUMMARY['packages']}")
    print(f"Links created:      {SUMMARY['links']}")
    print(f"Files copied:       {SUMMARY['copied']}")
    
    if SUMMARY["errors"]:
        print("\nERRORS:")
        for err in SUMMARY["errors"]:
            print(f" - {err}")
    else:
        print("\nNo errors encountered!")
    print("="*30)

if __name__ == "__main__":
    main()
