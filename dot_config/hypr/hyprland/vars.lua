return {
    terminal = "ghostty",
    browser = "helium-browser",
    fileManager = "nautilus --new-window",
    menu = "rofi -show drun -show-icons",
    powermenu = [[bash -lc 'choice=$(printf "  Shutdown\n  Reboot\n󰤄  Suspend\n  Lock\n  Logout" | rofi -dmenu -i -p "Power" -theme ~/.config/rofi/config.rasi); case "$choice" in *Shutdown*) systemctl poweroff ;; *Reboot*) systemctl reboot ;; *Suspend*) systemctl suspend ;; *Lock*) loginctl lock-session ;; *Logout*) hyprctl dispatch exit ;; esac']],
    mainMod = "SUPER",
}
