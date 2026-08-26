-- ~/.config/hypr/hyprland.lua
-- Modular Hyprland configuration with Noctalia Shell
-- Docs: https://wiki.hypr.land | https://docs.noctalia.dev

local config_dir = os.getenv("HOME") .. "/.config/hypr"
package.path = config_dir .. "/?.lua;" .. config_dir .. "/modules/?.lua;" .. package.path

-- Load modular configuration components
require("modules.env")
require("modules.autostart")
require("modules.monitors")
require("modules.look")
require("modules.keybinds")
require("modules.rules")
