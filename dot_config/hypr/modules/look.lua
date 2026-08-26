-- ~/.config/hypr/modules/look.lua
-- Appearance, Decorations, Animations, & Input

hl.config({
	general = {
		gaps_in          = 5,
		gaps_out         = 10,
		border_size      = 2,
		col = {
			active_border   = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
			inactive_border = "rgba(313244aa)",
		},
		resize_on_border = false,
		layout           = "dwindle",
	},

	decoration = {
		rounding       = 5,
		rounding_power = 2,
		shadow         = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
		blur           = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 },
	},

	input = {
		kb_layout     = "us",
		follow_mouse  = 2,
		accel_profile = "flat",
		touchpad      = { natural_scroll = false },
	},

	dwindle = { preserve_split = true },

	misc = {
		force_default_wallpaper = -1,
	},
})

-- 3-Finger workspace swipe gesture
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Snappier animations
hl.curve("snappy", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "global",           enabled = true,  speed = 4, bezier = "snappy" })
hl.animation({ leaf = "windows",          enabled = true,  speed = 3, bezier = "snappy" })
hl.animation({ leaf = "windowsOut",       enabled = false })
hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 2, bezier = "snappy" })
hl.animation({ leaf = "layers",           enabled = true,  speed = 2, bezier = "snappy" })
hl.animation({ leaf = "fade",             enabled = true,  speed = 3, bezier = "snappy" })
hl.animation({ leaf = "border",           enabled = true,  speed = 5, bezier = "snappy" })
hl.animation({ leaf = "borderangle",      enabled = false })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 3, bezier = "snappy" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 3, bezier = "snappy" })
hl.animation({ leaf = "monitorAdded",     enabled = true,  speed = 3, bezier = "snappy" })
