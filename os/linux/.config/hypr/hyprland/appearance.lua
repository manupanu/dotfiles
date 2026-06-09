return function()
    hl.config({
        general = {
            gaps_in = 4,
            gaps_out = 8,
            border_size = 2,
            col = {
                active_border = {
                    colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"},
                    angle = 45,
                },
                inactive_border = "rgba(313244aa)",
            },
            layout = "dwindle",
            resize_on_border = true,
        },
        decoration = {
            rounding = 10,
            active_opacity = 1.0,
            inactive_opacity = 0.94,
            shadow = {
                enabled = true,
                range = 18,
                render_power = 3,
                color = "rgba(00000066)",
            },
            blur = {
                enabled = true,
                size = 6,
                passes = 2,
                vibrancy = 0.16,
            },
        },
        animations = {
            enabled = true,
        },
        dwindle = {
            preserve_split = true,
        },
        misc = {
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            focus_on_activate = true,
            force_default_wallpaper = 0,
        },
    })

    hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })

    hl.animation({
        leaf = "windows",
        enabled = true,
        speed = 4,
        bezier = "easeOutQuint",
        style = "slide",
    })

    hl.animation({
        leaf = "windowsOut",
        enabled = true,
        speed = 4,
        bezier = "easeInOutCubic",
        style = "slide",
    })

    hl.animation({
        leaf = "border",
        enabled = true,
        speed = 8,
        bezier = "easeOutQuint",
    })

    hl.animation({
        leaf = "fade",
        enabled = true,
        speed = 4,
        bezier = "easeOutQuint",
    })

    hl.animation({
        leaf = "workspaces",
        enabled = true,
        speed = 4,
        bezier = "easeOutQuint",
        style = "slidefade",
    })
end
