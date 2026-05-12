-- ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({ animations = {
    enabled = true,
}})

hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1, 1.1},  {0.1, 1.1} } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3}, {0, 1} } })
hl.curve("liner",  { type = "bezier", points = { {1, 1},      {1, 1} } })

hl.animation({ leaf = "windows",      enabled = true, speed = 6,  curve = "wind",   style = "slide" })
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 6,  curve = "winIn",  style = "slide" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 5,  curve = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove",  enabled = true, speed = 5,  curve = "wind",   style = "slide" })
hl.animation({ leaf = "border",       enabled = true, speed = 1,  curve = "liner" })
hl.animation({ leaf = "borderangle",  enabled = true, speed = 30, curve = "liner",  style = "loop" })
hl.animation({ leaf = "fade",         enabled = true, speed = 10, curve = "default" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 5,  curve = "wind" })
