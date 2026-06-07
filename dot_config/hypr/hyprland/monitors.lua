return function()
    -- Specific current monitor from the ML4W/nwg-displays setup, plus a fallback for any other display.
    hl.monitor({
        output = "DP-2",
        mode = "3440x1440@239.99",
        position = "0x0",
        scale = 1.0,
    })

    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
    })
end
