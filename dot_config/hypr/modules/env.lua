-- ~/.config/hypr/modules/env.lua
-- Environment Variables

-- Cursor configuration
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

-- Wayland / Desktop environment identification
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt configuration
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- GTK configuration
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_THEME", "adw-gtk3-dark")

-- Electron / Chromium apps (Helium, VS Code, Discord, Slack, etc.)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Firefox Wayland native rendering
hl.env("MOZ_ENABLE_WAYLAND", "1")
