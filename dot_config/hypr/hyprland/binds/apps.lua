return function(vars)
    -- App and utility binds
    hl.bind(vars.mainMod .. " + Return", hl.dsp.exec_cmd(vars.terminal))
    hl.bind(vars.mainMod .. " + B", hl.dsp.exec_cmd(vars.browser))
    hl.bind(vars.mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager))
    hl.bind(vars.mainMod .. " + D", hl.dsp.exec_cmd(vars.menu))
    hl.bind(vars.mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill waybar; waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css"))
    hl.bind(vars.mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

    -- hyprwhspr speech-to-text
    -- Press once to start recording, press again to stop. Also visible/clickable in Waybar.
    hl.bind(vars.mainMod .. " + ALT + D", hl.dsp.exec_cmd("/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record"), {
        description = "Speech-to-text",
    })

    -- Screenshots and clipboard
    hl.bind(vars.mainMod .. " + Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
    hl.bind(vars.mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("grim - | wl-copy"))
    hl.bind(vars.mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"))
end
