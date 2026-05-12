
-- █▀▀ █▄░█ █░█
-- ██▄ █░▀█ ▀▄▀

hl.env("XCURSOR_SIZE", "24")


-- █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
-- █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

local mainMod = "SUPER"

hl.bind("CTRL + ALT + SHIFT + R",             hl.dsp.pass({ window = "^(com\\.obsproject\\.Studio)$" })) -- toggle obs screen recording // install obs
hl.bind(mainMod .. " + Period",               hl.dsp.exec_cmd("emote"))           -- launch emoji selector // install emote
hl.bind(mainMod .. " + ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd("hyprshade on blue-light-filter")) -- enable blue light filter // install hyprshade
hl.bind(mainMod .. " + ALT + XF86MonBrightnessUp",   hl.dsp.exec_cmd("hyprshade off")) -- disable blue light filter // install hyprshade


-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

-- hl.window_rule({ match = { class = "^(Steam)$" }, opacity = "0.60 0.60" })


-- █░█ █▀▄▀█
-- ▀▄▀ █░▀░█

hl.bind("CTRL + ALT_L + V", hl.dsp.submap("passthrough"))
hl.bind("CTRL + ALT_L + V", hl.dsp.submap("reset"), { submap = "passthrough" })
