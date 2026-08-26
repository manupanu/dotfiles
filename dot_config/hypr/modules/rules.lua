-- ~/.config/hypr/modules/rules.lua
-- Window Rules & Layer Blur Rules

-- Ignore maximize requests from apps (window stays tiled)
hl.window_rule({
	match          = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix XWayland drag issues
hl.window_rule({
	match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- Position hyprlauncher
hl.window_rule({
	match = { class = "hyprland-run" },
	move  = "20 monitor_h-120",
	float = true,
})

-- Helium picture-in-picture: fixed size, on top of everything, all workspaces
hl.window_rule({
	name  = "helium-pip",
	match = { title = "^Picture in picture$" },
	float = true,
	size  = { 896, 504 },
	move  = "0 monitor_h-504",
	pin   = true,
})

-- Float the Noctalia settings window
hl.window_rule({
	match = { class = "dev.noctalia.Noctalia" },
	float = true,
	size  = { 1080, 920 },
})

-- Blur and disable Hyprland layer animations on Noctalia layer surfaces
hl.layer_rule({
	name         = "noctalia-blur",
	match        = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
	no_anim      = true,
	ignore_alpha = 0.5,
	blur         = true,
	blur_popups  = true,
})
