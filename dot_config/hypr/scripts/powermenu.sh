#!/usr/bin/env bash
# Rofi Power Menu — Catppuccin Mocha
# Hyprland-compatible, no wlogout dependency

## Options with Nerd Font icons
shutdown='  Shutdown'
reboot='  Reboot'
suspend='󰤄  Suspend'
lock='  Lock'
logout='  Logout'

## Run rofi dmenu
chosen=$(printf "%s\n%s\n%s\n%s\n%s" \
    "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
    rofi -dmenu \
        -i \
        -p "Power" \
        -theme config-powermenu)

## Execute selection
case "$chosen" in
    "$lock")
        loginctl lock-session
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$logout")
        uwsm stop
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
