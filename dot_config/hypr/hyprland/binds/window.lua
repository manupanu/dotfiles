return function(vars)
    -- Window management
    hl.bind(vars.mainMod .. " + Q", hl.dsp.window.close())
    hl.bind(vars.mainMod .. " + SHIFT + Q", hl.dsp.exit())
    hl.bind(vars.mainMod .. " + F", hl.dsp.window.fullscreen())
    hl.bind(vars.mainMod .. " + M", hl.dsp.window.fullscreen())
    hl.bind(vars.mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(vars.mainMod .. " + P", hl.dsp.window.pin({ action = "toggle" }))
    hl.bind(vars.mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
    hl.bind(vars.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- Focus
    hl.bind(vars.mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
    hl.bind(vars.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(vars.mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
    hl.bind(vars.mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
    hl.bind(vars.mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
    hl.bind(vars.mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
    hl.bind(vars.mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
    hl.bind(vars.mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

    -- Swap windows
    hl.bind(vars.mainMod .. " + ALT + left", hl.dsp.window.swap({ direction = "left" }))
    hl.bind(vars.mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "right" }))
    hl.bind(vars.mainMod .. " + ALT + up", hl.dsp.window.swap({ direction = "up" }))
    hl.bind(vars.mainMod .. " + ALT + down", hl.dsp.window.swap({ direction = "down" }))

    -- Resize with keyboard
    hl.bind(vars.mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), {
        repeating = true,
    })
    hl.bind(vars.mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), {
        repeating = true,
    })
    hl.bind(vars.mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), {
        repeating = true,
    })
    hl.bind(vars.mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), {
        repeating = true,
    })

    -- Mouse resize/move
    hl.bind(vars.mainMod .. " + mouse:272", hl.dsp.window.drag(), {
        mouse = true,
    })
    hl.bind(vars.mainMod .. " + mouse:273", hl.dsp.window.resize(), {
        mouse = true,
    })
end
