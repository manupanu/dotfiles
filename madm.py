#!/usr/bin/env python3
import os
import sys
import shutil
import platform
import socket
import argparse
import json
import re
import subprocess
import difflib
import time
import fnmatch
from pathlib import Path, PurePosixPath

# Cache resolved 1Password secrets
OP_CACHE = {}
DRY_RUN = False
CURRENT_BACKUP_DIR = None
OP_ACCOUNT = None

# Color codes helper
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'
    
    ENABLED = True
    
    @classmethod
    def disable(cls):
        cls.GREEN = ''
        cls.YELLOW = ''
        cls.BLUE = ''
        cls.RED = ''
        cls.CYAN = ''
        cls.BOLD = ''
        cls.END = ''
        cls.ENABLED = False
        
    @classmethod
    def enable_windows_ansi(cls):
        if platform.system().lower() == "windows":
            try:
                import ctypes
                kernel32 = ctypes.windll.kernel32
                kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            except Exception:
                os.system('')

class ConfigObject:
    def __init__(self, d):
        self._d = d
        for k, v in d.items():
            if isinstance(v, dict):
                setattr(self, k, ConfigObject(v))
            else:
                setattr(self, k, v)
    def __getattr__(self, name):
        return ConfigObject({})
    def __str__(self):
        return ""
    def __repr__(self):
        return ""
    def __bool__(self):
        return bool(self._d)

def command_exists(cmd):
    return shutil.which(cmd) is not None

def read_file_content(path, repo_dir):
    file_path = Path(path)
    if not file_path.is_absolute():
        file_path = repo_dir / file_path
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        print(f"{Colors.RED}[Error]{Colors.END} read_file failed for '{path}': {e}", file=sys.stderr)
        return ""

def quote_val(val):
    escaped = str(val).replace('"', '\\"')
    return f'"{escaped}"'

def resolve_op_secret(ref, account_override=None):
    account = account_override or OP_ACCOUNT or os.environ.get("OP_ACCOUNT")
    cache_key = (account, ref)
    if cache_key in OP_CACHE:
        return OP_CACHE[cache_key]
    
    if DRY_RUN:
        return f"<1Password secret: {ref}>"
    
    if not shutil.which("op"):
        raise RuntimeError("1Password CLI 'op' is not installed or not in PATH")
        
    try:
        cmd = ["op", "read", ref]
        if account:
            cmd.extend(["--account", account])

        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        secret = res.stdout.strip()
        OP_CACHE[cache_key] = secret
        return secret
    except subprocess.CalledProcessError as e:
        account_msg = f" --account {account}" if account else ""
        print(f"{Colors.RED}[Error]{Colors.END} Running 'op read {ref}{account_msg}': {e.stderr}", file=sys.stderr)
        raise e

# ---------------------------------------------------------------------
# Ignore patterns
# ---------------------------------------------------------------------

def _ignore_subpaths(path_str):
    normalized = path_str.replace(os.sep, "/").strip("/")
    if not normalized:
        return []
    parts = PurePosixPath(normalized).parts
    return ["/".join(parts[:i]) for i in range(1, len(parts) + 1)]

def path_matches_ignore(path_str, patterns):
    if not patterns or not path_str:
        return False
    subpaths = _ignore_subpaths(path_str)
    for pattern in patterns:
        for sp in subpaths:
            if fnmatch.fnmatch(sp, pattern):
                return True
    return False

def is_ignored(src_rel, dst_rel, patterns):
    if not patterns:
        return False
    return path_matches_ignore(src_rel, patterns) or path_matches_ignore(dst_rel, patterns)

def mapping_dst_rel(dst_raw):
    # Best-effort target-relative path (relative to home) for ignore matching.
    dst_expanded = os.path.expanduser(os.path.expandvars(dst_raw))
    dst_path = Path(dst_expanded).absolute()
    try:
        return dst_path.relative_to(Path.home()).as_posix()
    except ValueError:
        return dst_path.as_posix()

# ---------------------------------------------------------------------
# Secret providers
# ---------------------------------------------------------------------

SECRET_PROVIDERS = {}

def register_secret_provider(name, fn):
    SECRET_PROVIDERS[name] = fn

def _provider_op(name, account=None):
    ref = name if name.startswith("op://") else f"op://{name}"
    return resolve_op_secret(ref, account_override=account)

def _provider_pass(name, account=None):
    if DRY_RUN:
        return f"<pass secret: {name}>"
    if not shutil.which("pass"):
        raise RuntimeError("'pass' is not installed or not in PATH")
    try:
        res = subprocess.run(["pass", "show", name], capture_output=True, text=True, check=True)
        return res.stdout.splitlines()[0].rstrip("\n") if res.stdout else ""
    except subprocess.CalledProcessError as e:
        print(f"{Colors.RED}[Error]{Colors.END} Running 'pass show {name}': {e.stderr}", file=sys.stderr)
        raise e

def _provider_env(name, account=None):
    value = os.environ.get(name)
    if value is None:
        raise RuntimeError(f"Environment variable '{name}' is not set")
    return value

register_secret_provider("op", _provider_op)
register_secret_provider("pass", _provider_pass)
register_secret_provider("env", _provider_env)

def resolve_secret(name, secrets_config, account=None):
    provider_name = secrets_config.get(name)
    if not provider_name:
        raise RuntimeError(
            f"No secret provider configured for '{name}'. Add it to the 'secrets' section of "
            "dotfiles.json or dotfiles.local.json, e.g. \"secrets\": {\"" + name + "\": \"op\"}"
        )
    fn = SECRET_PROVIDERS.get(str(provider_name).lower())
    if not fn:
        known = ", ".join(sorted(SECRET_PROVIDERS)) or "none"
        raise RuntimeError(f"Unknown secret provider '{provider_name}' for secret '{name}'. Known providers: {known}")
    if DRY_RUN and provider_name.lower() != "op":
        # op provider already handles DRY_RUN internally; mirror that behavior for others.
        if provider_name.lower() == "pass":
            return f"<pass secret: {name}>"
        if provider_name.lower() == "env" and name not in os.environ:
            return f"<env secret: {name}>"
    return fn(name, account)

def render_line(line, context):
    def repl(match):
        expr = match.group(1).strip()
        try:
            val = eval(expr, {}, context)
            if val is None:
                return ""
            return str(val)
        except Exception as e:
            print(f"{Colors.RED}[Error]{Colors.END} Evaluating expression '{expr}': {e}", file=sys.stderr)
            raise e
    return re.sub(r'\{\{(.*?)\}\}', repl, line)

def render_template(template_content, context):
    lines = template_content.splitlines()
    output = []
    stack = []
    
    for line_idx, line in enumerate(lines, 1):
        stripped = line.strip()
        
        if stripped.startswith("{{") and stripped.endswith("}}"):
            inner = stripped[2:-2].strip()
            if inner.startswith("-"):
                inner = inner[1:].strip()
            if inner.endswith("-"):
                inner = inner[:-1].strip()
                
            parts = inner.split(None, 1)
            command = parts[0] if parts else ""
            expr = parts[1] if len(parts) > 1 else ""
            
            if command == "if":
                parent_active = stack[-1][0] if stack else True
                if parent_active:
                    try:
                        cond = bool(eval(expr, {}, context))
                    except Exception as e:
                        raise ValueError(f"Error evaluating conditional '{expr}' at line {line_idx}: {e}")
                    stack.append((cond, cond))
                else:
                    stack.append((False, False))
                continue
                
            elif command == "elif":
                if not stack:
                    raise ValueError(f"Unexpected 'elif' without 'if' at line {line_idx}")
                parent_active = stack[-2][0] if len(stack) > 1 else True
                if parent_active:
                    if not stack[-1][1]:
                        try:
                            cond = bool(eval(expr, {}, context))
                        except Exception as e:
                            raise ValueError(f"Error evaluating conditional '{expr}' at line {line_idx}: {e}")
                        stack[-1] = (cond, cond)
                    else:
                        stack[-1] = (False, True)
                else:
                    stack[-1] = (False, False)
                continue
                
            elif command == "else":
                if not stack:
                    raise ValueError(f"Unexpected 'else' without 'if' at line {line_idx}")
                parent_active = stack[-2][0] if len(stack) > 1 else True
                if parent_active:
                    if not stack[-1][1]:
                        stack[-1] = (True, True)
                    else:
                        stack[-1] = (False, True)
                else:
                    stack[-1] = (False, False)
                continue
                
            elif command == "end":
                if not stack:
                    raise ValueError(f"Unexpected 'end' without 'if' at line {line_idx}")
                stack.pop()
                continue
        
        currently_active = stack[-1][0] if stack else True
        if currently_active:
            output.append(render_line(line, context))
            
    return "\n".join(output) + ("\n" if template_content.endswith("\n") else "")

def print_diff(dst_path, existing_content, new_content):
    existing_lines = existing_content.splitlines(keepends=True)
    new_lines = new_content.splitlines(keepends=True)
    diff = difflib.unified_diff(
        existing_lines, new_lines, 
        fromfile=str(dst_path), 
        tofile=str(dst_path) + " (new)"
    )
    
    has_diff = False
    for line in diff:
        has_diff = True
        if line.startswith('+') and not line.startswith('+++'):
            sys.stdout.write(f"{Colors.GREEN}{line}{Colors.END}")
        elif line.startswith('-') and not line.startswith('---'):
            sys.stdout.write(f"{Colors.RED}{line}{Colors.END}")
        elif line.startswith('@@'):
            sys.stdout.write(f"{Colors.CYAN}{line}{Colors.END}")
        else:
            sys.stdout.write(line)
    return has_diff

def handle_conflict(dst_path, dry_run=False, interactive=False, no_clobber=False):
    if not dst_path.exists() and not dst_path.is_symlink():
        return 'overwrite'
        
    if no_clobber:
        return 'skip'
        
    if not interactive:
        return 'backup'
        
    prompt = f"{Colors.YELLOW}[Conflict]{Colors.END} Target '{dst_path}' already exists. [o]verwrite, [b]ackup, [s]kip? (default: b): "
    try:
        ans = input(prompt).strip().lower()
    except (KeyboardInterrupt, EOFError):
        print(f"\n{Colors.RED}[Aborted]{Colors.END} Keyboard interrupt. Skipping.")
        return 'skip'
        
    if ans == 'o':
        return 'overwrite'
    elif ans == 's':
        return 'skip'
    else:
        return 'backup'

def get_backup_dir(repo_dir, dry_run=False):
    global CURRENT_BACKUP_DIR
    if CURRENT_BACKUP_DIR:
        return CURRENT_BACKUP_DIR
        
    backups_root = repo_dir / ".madm-backups"
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    backup_dir = backups_root / f"backup_{timestamp}"
    
    if not dry_run:
        backup_dir.mkdir(parents=True, exist_ok=True)
        metadata = {"files": {}}
        with open(backup_dir / "metadata.json", "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)
            
    CURRENT_BACKUP_DIR = backup_dir
    return CURRENT_BACKUP_DIR

def perform_backup(dst_path, repo_dir, dry_run=False):
    if not dst_path.exists() and not dst_path.is_symlink():
        return
        
    bdir = get_backup_dir(repo_dir, dry_run)
    
    if not dry_run:
        metadata_path = bdir / "metadata.json"
        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                metadata = json.load(f)
        except Exception:
            metadata = {"files": {}}
            
        index = len(metadata["files"])
        backup_filename = f"file_{index}"
        backup_path = bdir / backup_filename
        
        print(f"  {Colors.YELLOW}[Backup]{Colors.END} Moving existing target {dst_path} to backup folder")
        
        is_link = dst_path.is_symlink()
        is_directory = dst_path.is_dir() and not is_link
        
        if is_link:
            link_target = os.readlink(dst_path)
            metadata["files"][backup_filename] = {
                "original_dst": str(dst_path),
                "type": "link",
                "target": link_target
            }
            dst_path.unlink()
        elif is_directory:
            shutil.move(str(dst_path), str(backup_path))
            metadata["files"][backup_filename] = {
                "original_dst": str(dst_path),
                "type": "directory"
            }
        else:
            shutil.move(str(dst_path), str(backup_path))
            metadata["files"][backup_filename] = {
                "original_dst": str(dst_path),
                "type": "file"
            }
            
        with open(metadata_path, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)
    else:
        print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would backup existing target {dst_path} to centralized backups")

def check_and_elevate_windows():
    if platform.system().lower() == "windows":
        try:
            import ctypes
            if not ctypes.windll.shell32.IsUserAnAdmin():
                print(f"{Colors.YELLOW}[Elevation]{Colors.END} Symlinking requires Administrator permissions on Windows.")
                ans = input("Do you want to elevate to Administrator via UAC? [y/N]: ").strip().lower()
                if ans == 'y':
                    script = sys.argv[0]
                    args = " ".join(sys.argv[1:])
                    print("Prompting for UAC elevation...")
                    ret = ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, f'"{script}" {args}', None, 1)
                    if int(ret) > 32:
                        sys.exit(0)
                    else:
                        print(f"{Colors.RED}[Error]{Colors.END} Elevation failed (error code {ret}).")
        except Exception as e:
            print(f"{Colors.RED}[Error]{Colors.END} Failed to request elevation: {e}", file=sys.stderr)

def create_symlink(src_path, dst_path, repo_dir, dry_run=False, verbose=False, interactive=False, diff_mode=False, no_clobber=False):
    has_changes = True
    existing_target = ""
    
    if dst_path.exists() or dst_path.is_symlink():
        if dst_path.is_symlink():
            try:
                target = os.readlink(dst_path)
                existing_target = target
                if Path(target).absolute() == src_path.absolute():
                    has_changes = False
                    if verbose:
                        print(f"  {Colors.GREEN}[Skip]{Colors.END} Symlink {dst_path} already points to {src_path}")
                    return True
            except OSError:
                pass
                
    if diff_mode and has_changes:
        print(f"\n{Colors.BLUE}[Diff]{Colors.END} Symlink changes for {dst_path}:")
        if existing_target:
            print(f"{Colors.RED}- Existing target: {existing_target}{Colors.END}")
        else:
            print(f"{Colors.RED}- Existing file/directory: {dst_path}{Colors.END}")
        print(f"{Colors.GREEN}+ New symlink target: {src_path}{Colors.END}")
        
    if not dry_run:
        strategy = handle_conflict(dst_path, dry_run, interactive, no_clobber)
        if strategy == 'skip':
            print(f"  {Colors.YELLOW}[Skip]{Colors.END} Skipping mapping for {dst_path}")
            return True
            
        if strategy == 'backup' and (dst_path.exists() or dst_path.is_symlink()):
            perform_backup(dst_path, repo_dir, dry_run)
        elif strategy == 'overwrite' and (dst_path.exists() or dst_path.is_symlink()):
            print(f"  {Colors.RED}[Delete]{Colors.END} Overwriting existing file/link {dst_path}")
            if dst_path.is_dir() and not dst_path.is_symlink():
                shutil.rmtree(dst_path)
            else:
                dst_path.unlink()
                
        print(f"  {Colors.GREEN}[Link]{Colors.END} Linking {dst_path} -> {src_path}")
        is_dir = src_path.is_dir()
        try:
            os.symlink(src_path, dst_path, target_is_directory=is_dir)
        except PermissionError as e:
            if platform.system().lower() == "windows":
                check_and_elevate_windows()
                print(f"  {Colors.YELLOW}[Warning]{Colors.END} Symlink failed due to permissions. Attempting copy fallback on Windows...")
                return copy_path(src_path, dst_path, repo_dir, dry_run, verbose, interactive, diff_mode, no_clobber)
            else:
                raise e
        except OSError as e:
            if platform.system().lower() == "windows":
                print(f"  {Colors.YELLOW}[Warning]{Colors.END} Symlink failed: {e}. Attempting copy fallback on Windows...")
                return copy_path(src_path, dst_path, repo_dir, dry_run, verbose, interactive, diff_mode, no_clobber)
            else:
                raise e
    else:
        if not diff_mode:
            print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would link {dst_path} -> {src_path}")
    return True

def copy_path(src_path, dst_path, repo_dir, dry_run=False, verbose=False, interactive=False, diff_mode=False, no_clobber=False):
    has_changes = True
    existing_content = ""
    new_content = ""
    is_file = src_path.is_file()
    
    if is_file:
        with open(src_path, "r", encoding="utf-8", errors="ignore") as f:
            new_content = f.read()
        if dst_path.exists() and dst_path.is_file():
            try:
                with open(dst_path, "r", encoding="utf-8", errors="ignore") as f:
                    existing_content = f.read()
                if existing_content == new_content:
                    has_changes = False
                    if verbose:
                        print(f"  {Colors.GREEN}[Skip]{Colors.END} File {dst_path} already matches source")
                    return True
            except Exception:
                pass
                
    if diff_mode and has_changes and is_file:
        print(f"\n{Colors.BLUE}[Diff]{Colors.END} File changes for {dst_path}:")
        print_diff(dst_path, existing_content, new_content)
        
    if not dry_run:
        strategy = handle_conflict(dst_path, dry_run, interactive, no_clobber)
        if strategy == 'skip':
            print(f"  {Colors.YELLOW}[Skip]{Colors.END} Skipping mapping for {dst_path}")
            return True
            
        if strategy == 'backup' and (dst_path.exists() or dst_path.is_symlink()):
            perform_backup(dst_path, repo_dir, dry_run)
        elif strategy == 'overwrite' and (dst_path.exists() or dst_path.is_symlink()):
            print(f"  {Colors.RED}[Delete]{Colors.END} Overwriting existing file/directory {dst_path}")
            if dst_path.is_dir() and not dst_path.is_symlink():
                shutil.rmtree(dst_path)
            else:
                dst_path.unlink()
                
        print(f"  {Colors.GREEN}[Copy]{Colors.END} Copying {src_path} -> {dst_path}")
        if src_path.is_dir():
            shutil.copytree(src_path, dst_path)
        else:
            shutil.copy2(src_path, dst_path)
    else:
        if not diff_mode or not is_file:
            print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would copy {src_path} -> {dst_path}")
    return True

def render_and_write_template(src_path, dst_path, variables, repo_dir, dry_run=False, verbose=False, interactive=False, diff_mode=False, no_clobber=False):
    with open(src_path, "r", encoding="utf-8") as f:
        template_content = f.read()
        
    try:
        rendered = render_template(template_content, variables)
    except Exception as e:
        print(f"{Colors.RED}[Error]{Colors.END} Rendering template {src_path}: {e}", file=sys.stderr)
        return False
        
    has_changes = True
    existing_content = ""
    if dst_path.exists():
        try:
            with open(dst_path, "r", encoding="utf-8", errors="ignore") as f:
                existing_content = f.read()
            if existing_content == rendered:
                has_changes = False
                if verbose:
                    print(f"  {Colors.GREEN}[Skip]{Colors.END} Template {dst_path} already matches rendered content")
                return True
        except Exception:
            pass
            
    if diff_mode and has_changes:
        print(f"\n{Colors.BLUE}[Diff]{Colors.END} Template changes for {dst_path}:")
        print_diff(dst_path, existing_content, rendered)
        
    if not dry_run:
        strategy = handle_conflict(dst_path, dry_run, interactive, no_clobber)
        if strategy == 'skip':
            print(f"  {Colors.YELLOW}[Skip]{Colors.END} Skipping mapping for {dst_path}")
            return True
            
        if strategy == 'backup' and (dst_path.exists() or dst_path.is_symlink()):
            perform_backup(dst_path, repo_dir, dry_run)
        elif strategy == 'overwrite' and (dst_path.exists() or dst_path.is_symlink()):
            print(f"  {Colors.RED}[Delete]{Colors.END} Overwriting existing file {dst_path}")
            if dst_path.is_dir() and not dst_path.is_symlink():
                shutil.rmtree(dst_path)
            else:
                dst_path.unlink()
                
        print(f"  {Colors.BLUE}[Template]{Colors.END} Writing rendered {dst_path}")
        with open(dst_path, "w", encoding="utf-8") as f:
            f.write(rendered)
    else:
        if not diff_mode:
            print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would render and write {dst_path}")
    return True

def apply_mapping(mapping, variables, repo_dir, dry_run=False, verbose=False, interactive=False, diff_mode=False, no_clobber=False):
    src_rel = mapping["src"]
    dst_raw = mapping["dst"]
    op_type = mapping.get("type", "link")
    
    src_path = Path(src_rel).absolute()
    if not src_path.exists():
        print(f"{Colors.RED}[Error]{Colors.END} Source path '{src_path}' does not exist.", file=sys.stderr)
        return False
        
    dst_expanded = os.path.expanduser(dst_raw)
    dst_expanded = os.path.expandvars(dst_expanded)
    dst_path = Path(dst_expanded).absolute()
    
    if not dry_run:
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        
    if op_type == "link":
        return create_symlink(src_path, dst_path, repo_dir, dry_run, verbose, interactive, diff_mode, no_clobber)
    elif op_type == "copy":
        return copy_path(src_path, dst_path, repo_dir, dry_run, verbose, interactive, diff_mode, no_clobber)
    elif op_type == "template":
        return render_and_write_template(src_path, dst_path, variables, repo_dir, dry_run, verbose, interactive, diff_mode, no_clobber)
    else:
        print(f"{Colors.RED}[Error]{Colors.END} Unknown operation type '{op_type}' for mapping {src_rel} -> {dst_raw}", file=sys.stderr)
        return False

def run_script(script_path, dry_run=False):
    script = Path(script_path).absolute()
    if not script.exists():
        print(f"{Colors.RED}[Error]{Colors.END} Script '{script}' does not exist.", file=sys.stderr)
        return False
        
    ext = script.suffix.lower()
    
    if ext == ".ps1":
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script)]
    elif ext == ".sh":
        cmd = ["bash", str(script)]
    else:
        cmd = [str(script)]
        
    if not dry_run:
        print(f"  {Colors.CYAN}[Script]{Colors.END} Running: {' '.join(cmd)}")
        try:
            if ext == ".sh":
                os.chmod(script, os.stat(script).st_mode | 0o111)
            subprocess.run(cmd, check=True)
        except Exception as e:
            print(f"{Colors.RED}[Error]{Colors.END} Executing script {script_path}: {e}", file=sys.stderr)
            return False
    else:
        print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would execute: {' '.join(cmd)}")
    return True

def prune_links(config, current_os, current_hostname, repo_dir, dry_run=False, ignore_patterns=None):
    ignore_patterns = ignore_patterns or []
    active_targets = set()
    all_mapped_dsts = []
    
    for m in config.get("mappings", []):
        dst_expanded = os.path.expanduser(m["dst"])
        dst_expanded = os.path.expandvars(dst_expanded)
        dst_path = Path(dst_expanded).absolute()
        all_mapped_dsts.append(dst_path)
        
        m_os = m.get("os")
        m_host = m.get("hostname")
        if m_os:
            if isinstance(m_os, str) and m_os != current_os:
                continue
            if isinstance(m_os, list) and current_os not in m_os:
                continue
        if m_host:
            if isinstance(m_host, str) and m_host != current_hostname:
                continue
            if isinstance(m_host, list) and current_hostname not in m_host:
                continue
        if is_ignored(m["src"], mapping_dst_rel(m["dst"]), ignore_patterns):
            continue
        active_targets.add(dst_path)
        
    parent_dirs = set()
    for dst_path in all_mapped_dsts:
        parent_dirs.add(dst_path.parent)
        if dst_path.parent.parent != Path.home() and dst_path.parent.parent != Path("/"):
            parent_dirs.add(dst_path.parent.parent)
            
    repo_dir = repo_dir.absolute()
    pruned_any = False
    
    for pdir in sorted(parent_dirs):
        if not pdir.exists() or not pdir.is_dir():
            continue
            
        try:
            for item in pdir.iterdir():
                if item.is_symlink():
                    item_abs = item.absolute()
                    if item_abs in active_targets:
                        continue
                        
                    try:
                        target = Path(os.readlink(item)).absolute()
                    except OSError:
                        continue
                        
                    is_in_repo = False
                    try:
                        if repo_dir == target or repo_dir in target.parents:
                            is_in_repo = True
                    except Exception:
                        pass
                        
                    if is_in_repo:
                        pruned_any = True
                        if not dry_run:
                            print(f"  {Colors.RED}[Prune]{Colors.END} Removing stale link {item_abs} -> {target}")
                            item.unlink()
                        else:
                            print(f"  {Colors.BOLD}[Dry Run]{Colors.END} Would prune stale link {item_abs} -> {target}")
        except OSError as e:
            print(f"  {Colors.YELLOW}[Warning]{Colors.END} Could not scan directory {pdir}: {e}", file=sys.stderr)
            
    if not pruned_any:
        print("No stale links found to prune.")

def restore_backups(repo_dir):
    backups_root = repo_dir / ".madm-backups"
    if not backups_root.exists() or not backups_root.is_dir():
        print("No backups found to restore.")
        return
        
    backup_dirs = sorted([d for d in backups_root.iterdir() if d.is_dir() and d.name.startswith("backup_")])
    if not backup_dirs:
        print("No backups found to restore.")
        return
        
    print(f"\n{Colors.BOLD}{Colors.CYAN}--- Available Backups ---{Colors.END}\n")
    for idx, d in enumerate(backup_dirs):
        file_count = 0
        try:
            with open(d / "metadata.json", "r") as f:
                meta = json.load(f)
                file_count = len(meta.get("files", {}))
        except Exception:
            pass
        print(f"  [{idx}] {d.name} ({file_count} items backed up)")
        
    try:
        selection = input(f"\nSelect a backup to restore [0-{len(backup_dirs)-1}] (default: latest, q to quit): ").strip()
        if selection.lower() == 'q':
            print("Restore aborted.")
            return
        if not selection:
            sel_idx = len(backup_dirs) - 1
        else:
            sel_idx = int(selection)
            if sel_idx < 0 or sel_idx >= len(backup_dirs):
                raise ValueError()
    except (KeyboardInterrupt, EOFError):
        print("\nRestore aborted.")
        return
    except ValueError:
        print(f"{Colors.RED}[Error]{Colors.END} Invalid selection.")
        return
        
    selected_dir = backup_dirs[sel_idx]
    print(f"\nRestoring backup: {selected_dir.name}...")
    
    metadata_path = selected_dir / "metadata.json"
    if not metadata_path.exists():
        print(f"{Colors.RED}[Error]{Colors.END} metadata.json not found in backup directory.")
        return
        
    try:
        with open(metadata_path, "r", encoding="utf-8") as f:
            metadata = json.load(f)
    except Exception as e:
        print(f"{Colors.RED}[Error]{Colors.END} Reading metadata: {e}")
        return
        
    files = metadata.get("files", {})
    success = True
    for backup_filename, info in files.items():
        original_dst = Path(info["original_dst"])
        ftype = info["type"]
        src = selected_dir / backup_filename
        
        original_dst.parent.mkdir(parents=True, exist_ok=True)
        
        if original_dst.exists() or original_dst.is_symlink():
            print(f"  Target '{original_dst}' already exists on disk. Overwriting it.")
            if original_dst.is_dir() and not original_dst.is_symlink():
                shutil.rmtree(original_dst)
            else:
                original_dst.unlink()
                
        print(f"  Restoring {original_dst} ({ftype})...")
        try:
            if ftype == "link":
                os.symlink(info["target"], original_dst)
            elif ftype == "directory":
                shutil.move(str(src), str(original_dst))
            else:
                shutil.move(str(src), str(original_dst))
        except Exception as e:
            print(f"    {Colors.RED}[Error]{Colors.END} Failed to restore {original_dst}: {e}")
            success = False
            
    if success:
        try:
            shutil.rmtree(selected_dir)
            print(f"{Colors.GREEN}[Success]{Colors.END} Backup {selected_dir.name} successfully restored and cleaned up.")
        except Exception:
            print(f"{Colors.GREEN}[Success]{Colors.END} Backup restored, but failed to delete backup directory.")
    else:
        print(f"{Colors.YELLOW}[Warning]{Colors.END} Completed with some restore errors.")

def run_health_check(config, local_config, repo_dir, ignore_patterns=None):
    ignore_patterns = ignore_patterns or []
    print(f"\n{Colors.BOLD}{Colors.CYAN}--- madm.py Health Check ---{Colors.END}\n")
    
    print(f"{Colors.BOLD}1. Validating Templates (Cross-Platform)...{Colors.END}")
    templates_ok = True
    platforms = ["darwin", "linux", "windows"]
    
    for m in config.get("mappings", []):
        if is_ignored(m["src"], mapping_dst_rel(m["dst"]), ignore_patterns):
            continue
        if m.get("type") == "template":
            src_path = repo_dir / m["src"]
            if not src_path.exists():
                print(f"  {Colors.RED}[Fail]{Colors.END} Source template missing: {m['src']}")
                templates_ok = False
                continue
                
            try:
                with open(src_path, "r", encoding="utf-8") as f:
                    content = f.read()
            except Exception as e:
                print(f"  {Colors.RED}[Fail]{Colors.END} Reading template {m['src']}: {e}")
                templates_ok = False
                continue
                
            for plat in platforms:
                mock_context = {
                    "os": plat,
                    "hostname": "healthcheck-host",
                    "home_dir": "/Users/mock-home",
                    "git": ConfigObject(local_config.get("git", {})),
                    "op_settings": ConfigObject(local_config.get("op", {})),
                    "op_use_one_password": local_config.get("op", {}).get("useOnePassword", False),
                    "op_git_signing_key_ref": local_config.get("op", {}).get("gitSigningKeyRef", ""),
                    "op_account": local_config.get("op", {}).get("account", ""),
                    "op": lambda ref: f"<mock_op_secret_for_{ref}>",
                    "secret": lambda name: f"<mock_secret_{name}>",
                    "env": lambda k: f"<mock_env_{k}>",
                    "command_exists": lambda c: True,
                    "read_file": lambda p: f"<mock_file_{p}>",
                    "quote": quote_val
                }
                
                try:
                    render_template(content, mock_context)
                except Exception as e:
                    print(f"  {Colors.RED}[Fail]{Colors.END} Template {m['src']} failed to render for OS={plat}: {e}")
                    templates_ok = False
                    
    if templates_ok:
        print(f"  {Colors.GREEN}[OK]{Colors.END} All templates rendered successfully for darwin, linux, and windows.")
    else:
        print(f"  {Colors.RED}[Fail]{Colors.END} Some templates failed rendering checks.")
        
    print(f"\n{Colors.BOLD}2. Checking Mapping Status (Current OS/Hostname)...{Colors.END}")
    
    current_os = platform.system().lower()
    if current_os in ["windows", "microsoft"]:
        current_os = "windows"
    elif current_os in ["darwin", "macos"]:
        current_os = "darwin"
    elif current_os == "linux":
        current_os = "linux"
        
    current_hostname = socket.gethostname().split('.')[0]
    
    sync_ok = True
    for m in config.get("mappings", []):
        if is_ignored(m["src"], mapping_dst_rel(m["dst"]), ignore_patterns):
            continue
        m_os = m.get("os")
        m_host = m.get("hostname")
        if m_os:
            if isinstance(m_os, str) and m_os != current_os:
                continue
            if isinstance(m_os, list) and current_os not in m_os:
                continue
        if m_host:
            if isinstance(m_host, str) and m_host != current_hostname:
                continue
            if isinstance(m_host, list) and current_hostname not in m_host:
                continue
                
        src_path = repo_dir / m["src"]
        dst_expanded = os.path.expanduser(m["dst"])
        dst_expanded = os.path.expandvars(dst_expanded)
        dst_path = Path(dst_expanded).absolute()
        op_type = m.get("type", "link")
        
        status = "unknown"
        if not dst_path.exists() and not dst_path.is_symlink():
            status = f"{Colors.RED}Missing{Colors.END}"
            sync_ok = False
        else:
            if op_type == "link":
                if dst_path.is_symlink():
                    try:
                        target = os.readlink(dst_path)
                        if Path(target).absolute() == src_path.absolute():
                            status = f"{Colors.GREEN}In Sync (Linked){Colors.END}"
                        else:
                            status = f"{Colors.YELLOW}Out of Sync (Points to {target}){Colors.END}"
                            sync_ok = False
                    except OSError:
                        status = f"{Colors.RED}Not a Symlink{Colors.END}"
                        sync_ok = False
                else:
                    status = f"{Colors.RED}Not a Symlink{Colors.END}"
                    sync_ok = False
            elif op_type == "copy":
                if src_path.is_file():
                    if dst_path.is_file():
                        with open(src_path, "r", encoding="utf-8", errors="ignore") as f:
                            src_c = f.read()
                        with open(dst_path, "r", encoding="utf-8", errors="ignore") as f:
                            dst_c = f.read()
                        if src_c == dst_c:
                            status = f"{Colors.GREEN}In Sync (Copied){Colors.END}"
                        else:
                            status = f"{Colors.YELLOW}Out of Sync (Contents differ){Colors.END}"
                            sync_ok = False
                    else:
                        status = f"{Colors.RED}Type mismatch (Target is dir){Colors.END}"
                        sync_ok = False
                else:
                    status = f"{Colors.GREEN}Checked (Directory exists){Colors.END}"
            elif op_type == "template":
                context = {
                    "os": current_os,
                    "hostname": current_hostname,
                    "home_dir": Path.home().as_posix(),
                    "git": ConfigObject(local_config.get("git", {})),
                    "op_settings": ConfigObject(local_config.get("op", {})),
                    "op_use_one_password": local_config.get("op", {}).get("useOnePassword", False),
                    "op_git_signing_key_ref": local_config.get("op", {}).get("gitSigningKeyRef", ""),
                    "op_account": local_config.get("op", {}).get("account", ""),
                    "op": lambda ref: f"<op_{ref}>",
                    "env": os.environ.get,
                    "command_exists": command_exists,
                    "read_file": lambda p: read_file_content(p, repo_dir),
                    "quote": quote_val
                }
                try:
                    with open(src_path, "r", encoding="utf-8") as f:
                        tmpl_content = f.read()
                    rendered = render_template(tmpl_content, context)
                    if dst_path.is_file():
                        with open(dst_path, "r", encoding="utf-8", errors="ignore") as f:
                            dst_c = f.read()
                        if rendered == dst_c:
                            status = f"{Colors.GREEN}In Sync (Rendered){Colors.END}"
                        else:
                            status = f"{Colors.YELLOW}Out of Sync (Contents differ){Colors.END}"
                            sync_ok = False
                    else:
                        status = f"{Colors.RED}Not a file{Colors.END}"
                        sync_ok = False
                except Exception as e:
                    status = f"{Colors.RED}Render Error: {e}{Colors.END}"
                    sync_ok = False
                    
        print(f"  {m['src']} -> {m['dst']}: {status}")
        
    print(f"\n{Colors.BOLD}Summary:{Colors.END}")
    if templates_ok and sync_ok:
        print(f"  {Colors.GREEN}HEALTHY{Colors.END}: All checks passed.")
        sys.exit(0)
    else:
        print(f"  {Colors.RED}UNHEALTHY{Colors.END}: Some checks failed. Run `python3 madm.py` to fix sync issues.")
        sys.exit(1)

def load_config_file(config_path, repo_dir):
    config_path = Path(config_path)
    if not config_path.is_absolute():
        config_path = repo_dir / config_path
        
    if not config_path.exists():
        return {}
        
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"{Colors.RED}[Error]{Colors.END} Parsing config {config_path}: {e}", file=sys.stderr)
        return {}
        
    merged_mappings = data.get("mappings", [])
    merged_scripts = data.get("scripts", [])
    merged_data = data.copy()
    
    includes = data.get("includes", [])
    for inc in includes:
        inc_path = Path(inc)
        if not inc_path.is_absolute():
            inc_path = config_path.parent / inc_path
            
        inc_data = load_config_file(inc_path, repo_dir)
        
        merged_mappings.extend(inc_data.get("mappings", []))
        merged_scripts.extend(inc_data.get("scripts", []))
        
        for k, v in inc_data.items():
            if k not in ["mappings", "scripts", "includes"]:
                if k in merged_data and isinstance(merged_data[k], dict) and isinstance(v, dict):
                    merged_dict = merged_data[k].copy()
                    merged_dict.update(v)
                    merged_data[k] = merged_dict
                else:
                    merged_data[k] = v
                    
    merged_data["mappings"] = merged_mappings
    merged_data["scripts"] = merged_scripts
    return merged_data

def init_wizard(repo_dir):
    local_path = repo_dir / "dotfiles.local.json"
    if local_path.exists():
        print(f"{Colors.YELLOW}[Warning]{Colors.END} {local_path} already exists.")
        try:
            ans = input("Do you want to overwrite it? [y/N]: ").strip().lower()
            if ans != 'y':
                print("Aborted initialization.")
                return
        except (KeyboardInterrupt, EOFError):
            print("\nAborted.")
            return

    default_name = ""
    default_email = ""
    default_user = ""
    try:
        default_name = subprocess.run(["git", "config", "user.name"], capture_output=True, text=True).stdout.strip()
        default_email = subprocess.run(["git", "config", "user.email"], capture_output=True, text=True).stdout.strip()
        default_user = subprocess.run(["git", "config", "github.user"], capture_output=True, text=True).stdout.strip()
    except Exception:
        pass

    if not default_name:
        default_name = "Manuel Anrig"
    if not default_email:
        default_email = "me@manuelanrig.ch"
    if not default_user:
        default_user = "manupanu"

    print(f"\n{Colors.BOLD}{Colors.CYAN}--- madm.py Initialization Wizard ---{Colors.END}\n")
    try:
        name = input(f"Git Name [{default_name}]: ").strip() or default_name
        email = input(f"Git Email [{default_email}]: ").strip() or default_email
        username = input(f"Git Username [{default_user}]: ").strip() or default_user
        
        default_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClBF3x9IGzrqKGNUWa0O60eYndkvg+tcQFjR1qMYRMP"
        signing_key = input(f"Git SSH/GPG Signing Key [{default_key}]: ").strip() or default_key
        
        use_op_str = input("Use 1Password for commit signing? [Y/n]: ").strip().lower()
        use_op = use_op_str != 'n'
        
        op_ref = ""
        op_account = ""
        if use_op:
            default_ref = "op://Private/hoh6xyfxtij4tth5pus7nnmrc4/public key"
            op_ref = input(f"1Password Signing Key Reference [{default_ref}]: ").strip() or default_ref
            op_account = input("1Password Account (optional, e.g. DN67FSOAANHD5P2YMMKVMEM2TA): ").strip()
            
    except (KeyboardInterrupt, EOFError):
        print("\nAborted initialization.")
        return

    config_data = {
        "git": {
            "name": name,
            "email": email,
            "username": username,
            "signingKey": signing_key
        },
        "op": {
            "useOnePassword": use_op,
            "gitSigningKeyRef": op_ref,
            "account": op_account
        }
    }

    try:
        with open(local_path, "w", encoding="utf-8") as f:
            json.dump(config_data, f, indent=2)
        print(f"\n{Colors.GREEN}[Success]{Colors.END} Created local settings at {local_path}")
    except Exception as e:
        print(f"\n{Colors.RED}[Error]{Colors.END} Failed to write local settings: {e}", file=sys.stderr)

def main():
    global DRY_RUN, OP_ACCOUNT
    parser = argparse.ArgumentParser(description="Manuel's Agentic Dotfiles Manager")
    parser.add_argument("-d", "--dry-run", action="store_true", help="Dry run mode. Show what would be done.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output.")
    parser.add_argument("--diff", action="store_true", help="Show unified diffs of changes (implies dry-run).")
    parser.add_argument("--prune", action="store_true", help="Prune dead symlinks pointing to this repo.")
    parser.add_argument("-i", "--interactive", action="store_true", help="Prompt before overwriting existing files.")
    parser.add_argument("--no-clobber", action="store_true", help="Skip any mapping whose target already exists instead of backing it up or overwriting it.")
    parser.add_argument("--init", action="store_true", help="Initialize local settings file interactively.")
    parser.add_argument("--check", action="store_true", help="Run system status checks and validate templates.")
    parser.add_argument("--restore", action="store_true", help="Restore centralized backup folder.")
    parser.add_argument("--no-color", action="store_true", help="Disable colorized terminal logs.")
    parser.add_argument("--target-os", help="Override operating system (darwin, linux, windows).")
    parser.add_argument("--target-hostname", help="Override hostname.")
    args = parser.parse_args()

    if args.no_color or not sys.stdout.isatty():
        Colors.disable()
    else:
        Colors.enable_windows_ansi()

    repo_dir = Path(__file__).parent.absolute()

    if args.init:
        init_wizard(repo_dir)
        sys.exit(0)

    if args.restore:
        restore_backups(repo_dir)
        sys.exit(0)

    current_os = args.target_os or platform.system().lower()
    if current_os in ["windows", "microsoft"]:
        current_os = "windows"
    elif current_os in ["darwin", "macos"]:
        current_os = "darwin"
    elif current_os == "linux":
        current_os = "linux"

    current_hostname = args.target_hostname or socket.gethostname().split('.')[0]

    DRY_RUN = args.dry_run or args.diff

    if args.verbose:
        print(f"System: OS={current_os}, Hostname={current_hostname}")

    config_path = repo_dir / "dotfiles.json"
    if not config_path.exists():
        print(f"{Colors.RED}[Error]{Colors.END} dotfiles.json not found in {repo_dir}", file=sys.stderr)
        sys.exit(1)

    config = load_config_file(config_path, repo_dir)
    if not config:
        print(f"{Colors.RED}[Error]{Colors.END} Loading dotfiles.json failed.", file=sys.stderr)
        sys.exit(1)

    if args.prune:
        local_config = {}
        local_path = repo_dir / "dotfiles.local.json"
        if local_path.exists():
            local_config = load_config_file(local_path, repo_dir)
        ignore_patterns = config.get("ignore", []) + local_config.get("ignore", [])
        print(f"Pruning dead symlinks for OS={current_os}, Hostname={current_hostname}...")
        prune_links(config, current_os, current_hostname, repo_dir, dry_run=DRY_RUN, ignore_patterns=ignore_patterns)
        sys.exit(0)

    local_config = {}
    local_path = repo_dir / "dotfiles.local.json"
    if local_path.exists():
        local_config = load_config_file(local_path, repo_dir)

    OP_ACCOUNT = local_config.get("op", {}).get("account") or os.environ.get("OP_ACCOUNT")

    secrets_config = {}
    secrets_config.update(config.get("secrets", {}))
    secrets_config.update(local_config.get("secrets", {}))

    ignore_patterns = config.get("ignore", []) + local_config.get("ignore", [])

    if args.check:
        run_health_check(config, local_config, repo_dir, ignore_patterns=ignore_patterns)
        sys.exit(0)

    context = {
        "os": current_os,
        "hostname": current_hostname,
        "home_dir": Path.home().as_posix(),
        "git": ConfigObject(local_config.get("git", {})),
        "op_settings": ConfigObject(local_config.get("op", {})),
        "op_use_one_password": local_config.get("op", {}).get("useOnePassword", False),
        "op_git_signing_key_ref": local_config.get("op", {}).get("gitSigningKeyRef", ""),
        "op_account": local_config.get("op", {}).get("account", ""),
        "op": resolve_op_secret,
        "secret": lambda name: resolve_secret(name, secrets_config, OP_ACCOUNT),
        "env": os.environ.get,
        "command_exists": command_exists,
        "read_file": lambda p: read_file_content(p, repo_dir),
        "quote": quote_val
    }
    
    for k, v in local_config.items():
        if k not in ["git", "op", "secrets"]:
            context[k] = ConfigObject(v) if isinstance(v, dict) else v

    scripts = config.get("scripts", [])
    pre_scripts = [s for s in scripts if s.get("stage", "post") == "pre"]
    post_scripts = [s for s in scripts if s.get("stage", "post") == "post"]

    def script_matches(s):
        s_os = s.get("os")
        s_host = s.get("hostname")
        if s_os:
            if isinstance(s_os, str) and s_os != current_os:
                return False
            if isinstance(s_os, list) and current_os not in s_os:
                return False
        if s_host:
            if isinstance(s_host, str) and s_host != current_hostname:
                return False
            if isinstance(s_host, list) and current_hostname not in s_host:
                return False
        return True

    for s in pre_scripts:
        if script_matches(s):
            script_full_path = repo_dir / s["path"]
            if not run_script(script_full_path, dry_run=DRY_RUN):
                print(f"{Colors.RED}[Error]{Colors.END} Pre-script {s['path']} failed. Aborting.", file=sys.stderr)
                sys.exit(1)

    mappings = config.get("mappings", [])
    success = True
    for m in mappings:
        m_os = m.get("os")
        m_host = m.get("hostname")
        if m_os:
            if isinstance(m_os, str) and m_os != current_os:
                continue
            if isinstance(m_os, list) and current_os not in m_os:
                continue
        if m_host:
            if isinstance(m_host, str) and m_host != current_hostname:
                continue
            if isinstance(m_host, list) and current_hostname not in m_host:
                continue

        if is_ignored(m["src"], mapping_dst_rel(m["dst"]), ignore_patterns):
            if args.verbose:
                print(f"  {Colors.YELLOW}[Ignore]{Colors.END} Skipping {m['src']} -> {m['dst']} (matched ignore pattern)")
            continue

        m_resolved = m.copy()
        m_resolved["src"] = str(repo_dir / m["src"])
        
        if args.verbose:
            print(f"Processing: {m['src']} -> {m['dst']}")
        if not apply_mapping(m_resolved, context, repo_dir, dry_run=DRY_RUN, verbose=args.verbose, interactive=args.interactive, diff_mode=args.diff, no_clobber=args.no_clobber):
            print(f"{Colors.RED}[Error]{Colors.END} Applying mapping: {m['src']} -> {m['dst']}", file=sys.stderr)
            success = False

    if not success:
        print("Completed with errors.", file=sys.stderr)
        sys.exit(1)

    for s in post_scripts:
        if script_matches(s):
            script_full_path = repo_dir / s["path"]
            if not run_script(script_full_path, dry_run=DRY_RUN):
                print(f"{Colors.RED}[Error]{Colors.END} Post-script {s['path']} failed.", file=sys.stderr)
                sys.exit(1)

    print(f"{Colors.GREEN}[Success]{Colors.END} Execution completed successfully!")

if __name__ == "__main__":
    main()
