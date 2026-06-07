-- Manuel's Hyprland config
-- Single Lua source of truth. No ML4W, no generated config.
-- Managed by chezmoi from ~/.dotfiles/dot_config/hypr/hyprland.lua


-- -----------------------------------------------------------------------------
-- Variables and preferred apps
-- -----------------------------------------------------------------------------
var_terminal = "ghostty"
var_browser = "helium-browser"
var_fileManager = "nautilus --new-window"
var_menu = "rofi -show drun -show-icons"
var_mainMod = "SUPER"

-- Variables and preferred apps

-- -----------------------------------------------------------------------------
-- Monitors
-- -----------------------------------------------------------------------------
-- Monitor layout

-- Specific current monitor from the ML4W/nwg-displays setup, plus a fallback for any other display.
hl.monitor({
    output = "DP-2",
    mode = "3440x1440@239.99",
    position = "0x0",
    scale = 1.0,
})
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- -----------------------------------------------------------------------------
-- Environment
-- -----------------------------------------------------------------------------
-- Environment

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

-- -----------------------------------------------------------------------------
-- Autostart
-- -----------------------------------------------------------------------------
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css")
    hl.exec_cmd("swaync")
    hl.exec_cmd("wl-paste --watch cliphist store")
end)

-- hyprwhspr is installed as a user service; restart it after the Wayland session is ready.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user restart hyprwhspr.service")
end)

-- -----------------------------------------------------------------------------
-- Appearance
-- -----------------------------------------------------------------------------
-- Look and feel
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = {
                colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"},
                angle = 45,
            },
            inactive_border = "rgba(313244aa)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.94,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(00000066)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.16,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        force_default_wallpaper = 0,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "slide",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "easeInOutCubic",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 8,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "slidefade",
})

-- -----------------------------------------------------------------------------
-- Input
-- -----------------------------------------------------------------------------
-- Keyboard, pointer, and touchpad
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- -----------------------------------------------------------------------------
-- Window rules
-- -----------------------------------------------------------------------------
-- Window rules

-- Hyprland 0.55 tightened rule syntax, so this base stays conservative.

-- Add app-specific rules here as your rice evolves.

-- -----------------------------------------------------------------------------
-- App and utility binds
-- -----------------------------------------------------------------------------
-- App and utility binds
hl.bind(var_mainMod .. " + Return", hl.dsp.exec_cmd(var_terminal))
hl.bind(var_mainMod .. " + B", hl.dsp.exec_cmd(var_browser))
hl.bind(var_mainMod .. " + E", hl.dsp.exec_cmd(var_fileManager))
hl.bind(var_mainMod .. " + D", hl.dsp.exec_cmd(var_menu))
hl.bind(var_mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill waybar; waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css"))
hl.bind(var_mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- hyprwhspr speech-to-text

-- Press once to start recording, press again to stop. Also visible/clickable in Waybar.
hl.bind(var_mainMod .. " + ALT + D", hl.dsp.exec_cmd("/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record"), {
    description = "Speech-to-text",
})

-- Screenshots and clipboard
hl.bind(var_mainMod .. " + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(var_mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(var_mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"))

-- -----------------------------------------------------------------------------
-- Window management binds
-- -----------------------------------------------------------------------------
-- Window management
hl.bind(var_mainMod .. " + Q", hl.dsp.window.close())
hl.bind(var_mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(var_mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(var_mainMod .. " + M", hl.dsp.window.fullscreen())
hl.bind(var_mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var_mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(var_mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Focus
hl.bind(var_mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(var_mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Swap windows
hl.bind(var_mainMod .. " + ALT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind(var_mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(var_mainMod .. " + ALT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind(var_mainMod .. " + ALT + down", hl.dsp.window.swap({ direction = "down" }))

-- Resize with keyboard
hl.bind(var_mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), {
    repeating = true,
})
hl.bind(var_mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), {
    repeating = true,
})
hl.bind(var_mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), {
    repeating = true,
})
hl.bind(var_mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), {
    repeating = true,
})

-- Mouse resize/move
hl.bind(var_mainMod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true,
})
hl.bind(var_mainMod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true,
})

-- -----------------------------------------------------------------------------
-- Workspace binds
-- -----------------------------------------------------------------------------
-- Workspaces 1-10
hl.bind(var_mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(var_mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(var_mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(var_mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(var_mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(var_mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(var_mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(var_mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(var_mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(var_mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(var_mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(var_mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(var_mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(var_mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(var_mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(var_mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(var_mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(var_mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(var_mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(var_mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(var_mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(var_mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- -----------------------------------------------------------------------------
-- Media binds
-- -----------------------------------------------------------------------------
-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), {
    repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
    repeating = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), {
    repeating = true,
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), {
    repeating = true,
})
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
