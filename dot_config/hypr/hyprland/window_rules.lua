return function()
    -- Hyprland 0.55 tightened rule syntax, so this base stays conservative.
    hl.config({
        windowrule = {
            "float, title:^(Picture in picture)$",
            "pin, title:^(Picture in picture)$",
        },
    })
end
