-- ~/.config/hypr/modules/autostart.lua
-- Autostart Services & Applications

hl.on("hyprland.start", function()
	-- D-Bus / systemd Wayland environment activation
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME")

	-- Allow root GUI applications on Wayland (e.g. CachyOS package installer, gparted)
	hl.exec_cmd("xhost +SI:localuser:root")

	-- Noctalia desktop shell (bar, launcher, control center, notifications, lockscreen)
	hl.exec_cmd("noctalia")

	-- Clipboard manager daemon (if cliphist is installed)
	if os.execute("which cliphist >/dev/null 2>&1") == 0 then
		hl.exec_cmd("uwsm app -s b -- wl-paste --type text --watch cliphist store")
		hl.exec_cmd("uwsm app -s b -- wl-paste --type image --watch cliphist store")
	end

	-- Note: 1Password is automatically launched by UWSM via ~/.config/autostart/1password.desktop

	-- Nextcloud desktop client (start minimized to tray)
	hl.exec_cmd("uwsm app -s b -- nextcloud --background")

	-- Voxtype voice-to-text daemon
	hl.exec_cmd("systemctl --user start voxtype.service")

	-- Set cursor theme
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)
