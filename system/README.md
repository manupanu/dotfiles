# Root-owned system files (not managed by chezmoi)

Copy by hand, they live outside `$HOME`:

| File here | Install to | Notes |
| :-- | :-- | :-- |
| `etc/greetd/config.toml` | `/etc/greetd/config.toml` | replace `/home/manuel` with your home |
| `etc/greetd/tuigreet-launch` | `/etc/greetd/tuigreet-launch` (mode 755) | Catppuccin Mocha console palette + tuigreet theme |
| `etc/scx_loader/config.toml` | `/etc/scx_loader/config.toml` | default sched-ext scheduler (`scx_bpfland`) |

Keyring auto-unlock needs these three lines appended to `/etc/pam.d/greetd`:

```
auth       optional   pam_gnome_keyring.so
session    optional   pam_gnome_keyring.so auto_start
password   optional   pam_gnome_keyring.so
```

Then: `sudo systemctl enable greetd scx_loader` (and disable any other display manager).
