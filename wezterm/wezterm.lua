-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- Appearance settings:
config.font_size = 14
config.initial_cols = 150
config.initial_rows = 40
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 0.8
config.macos_window_background_blur = 10
config.window_decorations = 'RESIZE'
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.default_cursor_style = 'BlinkingBlock'
config.window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	}



-- Finally, return the configuration to wezterm:
return config