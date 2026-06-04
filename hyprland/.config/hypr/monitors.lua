-- █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
-- █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

--
hl.monitor({
    output = "desc:Dell Inc. DELL S3422DWG DKQVS63",
    mode = "3440x1440@143.97Hz",
    position = "0x0",
    scale = 1,
    icc = "/usr/share/color/icc/colord/S3422DWG.icc",
})
hl.monitor({
    output = "desc:Dell Inc. DELL U2415 XKV0P0414WMU",
    mode = "1920x1200@59.95Hz",
    position = "3440x-180",
    scale = 1,
    transform = 3,
})

-- █▀▄▀█ █ █▀ █▀▀
-- █░▀░█ █ ▄█ █▄▄

-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({ misc = {
    vrr = 2,
} })
