-- Manuel's Hyprland config
-- Split into modules for readability.
-- Managed by chezmoi from ~/.dotfiles/dot_config/hypr/hyprland.lua

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)")

local function load_module(name)
    return dofile(script_dir .. "hyprland/" .. name .. ".lua")
end

local vars = load_module("vars")

load_module("monitors")()
load_module("environment")()
load_module("autostart")()
load_module("appearance")()
load_module("input")()
load_module("window_rules")()

load_module("binds/apps")(vars)
load_module("binds/window")(vars)
load_module("binds/workspace")(vars)
load_module("binds/media")()
