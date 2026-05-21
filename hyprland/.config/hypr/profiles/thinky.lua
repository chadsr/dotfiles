hl.env("GDK_SCALE", 1)

hl.monitor({ output = "eDP-1", mode = "2560x1440@60.0", position = "0x0", scale = 1.25 })

hl.device({ name = "wacom-pen-and-multitouch-sensor-pen", output = "eDP-1", enabled = true })

-- Battery Optimisations:
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Performance/#how-do-i-make-hyprland-draw-as-little-power-as-possible-on-my-laptop
hl.config({ decoration = { blur = { enabled = false } } })
hl.config({ decoration = { shadow = { enabled = false } } })
