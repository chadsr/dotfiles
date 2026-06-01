local colors = require("themes.catppuccin-mocha")
local active_gradient = {
	colors = {
		"rgba(" .. colors.mauveAlpha .. "ff)",
		"rgba(" .. colors.lavenderAlpha .. "ff)",
		"rgba(" .. colors.sapphireAlpha .. "ff)",
	},
	angle = 45,
}
local inactive_gradient = { colors = { "rgba(" .. colors.mauveAlpha .. "80)" }, angle = 45 }

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
			xray = true,
		},
	},
})
