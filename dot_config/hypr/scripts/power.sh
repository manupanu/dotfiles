#!/usr/bin/env bash

case "$1" in
    lock)
        loginctl lock-session
        ;;
    exit | logout)
        hyprctl dispatch exit
        ;;
    suspend)
        systemctl suspend
        ;;
    reboot)
        systemctl reboot
        ;;
    shutdown | poweroff)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|exit|suspend|reboot|shutdown}"
        exit 1
        ;;
esac
