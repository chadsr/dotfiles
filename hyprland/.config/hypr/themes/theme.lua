local active_gradient = { colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" }, angle = 45 }
local inactive_gradient = { colors = { "rgba(b4befecc)", "rgba(6c7086cc)" }, angle = 45 }

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = active_gradient,
            inactive_border = inactive_gradient,
        },
        layout = "dwindle",
        resize_on_border = true,
    },
})

hl.config({
    group = {
        col = {
            border_active = active_gradient,
            border_inactive = inactive_gradient,
            border_locked_active = active_gradient,
            border_locked_inactive = inactive_gradient,
        },
    },
})

hl.config({
    decoration = {
        rounding = 0,

        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
        },
    },
})
