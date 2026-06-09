return function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
        hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
        hl.exec_cmd("waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css")
        hl.exec_cmd("swaync")
        hl.exec_cmd("wl-paste --watch cliphist store")

        -- Ensure wallpaper daemon is running and apply the default wallpaper.
        hl.exec_cmd("bash -lc 'pgrep -x awww-daemon >/dev/null || (nohup awww-daemon >/dev/null 2>&1 &); for i in $(seq 1 20); do awww query >/dev/null 2>&1 && break; sleep 0.1; done; awww img \"$HOME/Pictures/Wallpapers/wallhaven-1p5z71_3840x1600.png\"'")
    end)

    -- hyprwhspr is installed as a user service; restart it after the Wayland session is ready.
    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user restart hyprwhspr.service")
    end)
end
