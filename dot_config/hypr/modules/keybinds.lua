-- ~/.config/hypr/modules/keybinds.lua
-- Keybindings & Noctalia IPC Controls

local mainMod     = "SUPER"
local ipc         = "noctalia msg "
local terminal    = "kitty"
local fileManager = "nautilus"

-- Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())

-- Windows & Layouts
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Voice Dictation (Voxtype)
hl.bind(mainMod .. " + less", hl.dsp.exec_cmd("voxtype record toggle"))


-- Noctalia Panels & Surfaces
hl.bind(mainMod .. " + Space",         hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S",             hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma",         hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab",                   hl.dsp.exec_cmd(ipc .. "window-switcher"))
hl.bind("CTRL + ALT + Delete",         hl.dsp.exec_cmd(ipc .. "panel-toggle session"))

-- Noctalia Actions & Utilities
hl.bind(mainMod .. " + L",             hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind(mainMod .. " + SHIFT + S",     hl.dsp.exec_cmd(ipc .. "screenshot-region"))
hl.bind("Print",                       hl.dsp.exec_cmd(ipc .. "screenshot-region"))
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))
hl.bind("SHIFT + Print",               hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + SHIFT + D",     hl.dsp.exec_cmd(ipc .. "notification-dnd-toggle"))
hl.bind(mainMod .. " + N",             hl.dsp.exec_cmd(ipc .. "nightlight-toggle"))

-- Focus Navigation (Arrow Keys)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces (1-10) & Move Active Window (SHIFT + 1-10)
for i = 1, 10 do
	local key = i % 10 -- 10 -> key 0
	hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Drag / resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Scratchpad (Special Workspace)
hl.bind(mainMod .. " + A",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:magic" }))

-- Hardware keys (routed through Noctalia IPC for OSD popups)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(ipc .. "volume-mute"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(ipc .. "mic-mute"),        { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd(ipc .. "brightness-up"),   { locked = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd(ipc .. "brightness-down"), { locked = true })

-- Media keys (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
