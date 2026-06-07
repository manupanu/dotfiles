return function()
    -- Keep Electron/Qt/SDL/Clutter apps on Wayland where possible.
    hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_TYPE", "wayland")
    hl.env("GDK_BACKEND", "wayland")
    hl.env("QT_QPA_PLATFORM", "wayland;xcb")
    hl.env("SDL_VIDEODRIVER", "wayland")
    hl.env("CLUTTER_BACKEND", "wayland")
    hl.env("MOZ_ENABLE_WAYLAND", "1")
    hl.env("NIXOS_OZONE_WL", "1")
    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
end
