-- ~/.config/hypr/modules/autostart.lua
-- Autostart Services & Applications

hl.on("hyprland.start", function()
	-- D-Bus / systemd Wayland environment activation (for portals, screen share, 1Password)
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME")

	-- Polkit authentication agent (for privilege elevation prompts)
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

	-- Noctalia desktop shell (bar, launcher, control center, notifications, lockscreen)
	hl.exec_cmd("noctalia")

	-- Clipboard manager daemon (records text and images into cliphist)
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- 1Password background agent
	hl.exec_cmd("sh -c 'sleep 3 && exec 1password --silent'")

	-- Set cursor theme
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)
