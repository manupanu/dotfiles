import os
import sys
import json
import shutil
import socket
import subprocess
from pathlib import Path

def get_platform():
    if sys.platform == "win32": return "win32"
    if sys.platform == "darwin": return "darwin"
    return "linux"

def run_cmd(cmd, sudo=False):
    if sudo and get_platform() != "win32":
        cmd = ["sudo"] + cmd
    print(f"-> Running: {' '.join(cmd)}")
    try:
        subprocess.check_call(cmd)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")

def install_packages(packages):
    plat = get_platform()
    if plat not in packages: return
    pkgs = packages[plat]
    
    if plat == "darwin":
        run_cmd(["brew", "install"] + pkgs)
    elif plat == "linux":
        run_cmd(["apt-get", "install", "-y"] + pkgs, sudo=True)
    elif plat == "win32":
        for pkg in pkgs:
            try:
                result = subprocess.run(["winget", "list", "--exact", pkg], capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"Package {pkg} already installed.")
                    continue
            except Exception:
                pass
            run_cmd(["winget", "install", "--exact", pkg])

def setup_symlink(src, dst):
    dst = Path(dst).expanduser()
    src = Path(src).resolve()
    
    if not src.exists():
        print(f"Source missing: {src}")
        return

    if dst.exists() or dst.is_symlink():
        try:
            if dst.is_symlink() and Path(os.readlink(dst)).resolve() == src:
                print(f"Checked: {dst} already linked.")
                return
        except OSError:
            pass
        
        backup = dst.parent / (dst.name + ".bak")
        print(f"Backing up {dst} to {backup}")
        if backup.exists():
            if backup.is_dir(): shutil.rmtree(backup)
            else: os.remove(backup)
        shutil.move(str(dst), str(backup))

    dst.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        if get_platform() == "win32":
            os.symlink(src, dst, target_is_directory=src.is_dir())
        else:
            os.symlink(src, dst)
        print(f"Linked: {dst} -> {src}")
    except OSError as e:
        print(f"Failed to link {dst}: {e}")
        if get_platform() == "win32":
            print("Try enabling Developer Mode or running as Administrator.")

def setup_copy(src, dst):
    dst = Path(dst).expanduser()
    src = Path(src).resolve()
    
    if not src.exists():
        print(f"Source missing: {src}")
        return

    if dst.exists() or dst.is_symlink():
        backup = dst.parent / (dst.name + ".bak")
        print(f"Backing up {dst} to {backup}")
        if backup.exists():
            if backup.is_dir(): shutil.rmtree(backup)
            else: os.remove(backup)
        shutil.move(str(dst), str(backup))

    dst.parent.mkdir(parents=True, exist_ok=True)
    
    if src.is_dir():
        shutil.copytree(src, dst)
    else:
        shutil.copy2(src, dst)
    print(f"Copied: {dst} <- {src}")

def process_links(links_dict, module_dir, hostname, action_fn):
    for src, dst in links_dict.get("all", {}).items():
        action_fn(module_dir / src, dst)
        
    hostnames_config = links_dict.get("hostnames", {})
    matched = False
    
    for host_key, host_files in hostnames_config.items():
        if host_key == "default":
            continue
        target_hosts = [h.strip() for h in host_key.split(",")]
        if hostname in target_hosts:
            matched = True
            for src, dst in host_files.items():
                action_fn(module_dir / src, dst)
    
    if not matched and "default" in hostnames_config:
        for src, dst in hostnames_config["default"].items():
            action_fn(module_dir / src, dst)

def main():
    hostname = socket.gethostname()
    print(f"Hostname: {hostname}")
    root = Path(__file__).parent.resolve()
    modules_dir = root / "modules"
    
    if not modules_dir.exists():
        print("No modules directory found.")
        return

    for module_path in modules_dir.glob("**/module.json"):
        with open(module_path) as f:
            config = json.load(f)
        
        if "platforms" in config and get_platform() not in config["platforms"]:
            print(f"Skipping Module: {config.get('name', 'unknown')} (Platform mismatch)")
            continue
            
        if "hostnames" in config:
            allowed_hosts = config["hostnames"]
            if isinstance(allowed_hosts, str):
                allowed_hosts = [h.strip() for h in allowed_hosts.split(",")]
            
            if hostname not in allowed_hosts:
                print(f"Skipping Module: {config.get('name', 'unknown')} (Hostname mismatch)")
                continue

        print(f"\n--- Processing Module: {config.get('name', 'unknown')} ---")
        
        if "packages" in config:
            install_packages(config["packages"])
            
        if "links" in config:
            process_links(config["links"], module_path.parent, hostname, setup_symlink)
        
        if "copy" in config:
            process_links(config["copy"], module_path.parent, hostname, setup_copy)

if __name__ == "__main__":
    main()
