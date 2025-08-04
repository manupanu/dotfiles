-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()
local launch_menu = {}

-- Default shell
config.default_prog = { 'pwsh.exe', '-NoLogo' }

table.insert(launch_menu, {
  label = 'WSL',
  args = { 'wsl.exe'},
})
table.insert(launch_menu, {
  label = 'Pwsh',
  args = { 'pwsh.exe', '-NoLogo' },
})

-- Window geometry
config.initial_cols = 150
config.initial_rows = 40

-- Appearance settings
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14
config.color_scheme = 'Catppuccin Mocha'
config.win32_system_backdrop = 'Acrylic'
config.launch_menu = launch_menu
-- config.window_decorations = 'RESIZE'

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- Cursor
config.default_cursor_style = 'BlinkingBlock'

-- Window padding
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Finally, return the configuration to wezterm:
return config