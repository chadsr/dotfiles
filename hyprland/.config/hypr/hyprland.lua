-- █░░ ▄▀█ █░█ █▄░█ █▀▀ █░█
-- █▄▄ █▀█ █▄█ █░▀█ █▄▄ █▀█

-- See https://wiki.hypr.land/Configuring/Start/

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")                                                        -- for XDPH
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")                                                                                      -- for XDPH
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")                                                                 -- for XDPH
    hl.exec_cmd("systemctl --user start hypr-session.target")
    hl.exec_cmd("hyprpm reload")
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/gsettings-gtk")
    hl.exec_cmd("sunsetr preset default")
end)

-- █▀▀ █▄░█ █░█
-- ██▄ █░▀█ ▀▄▀

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

os.setenv("XDG_CURRENT_DESKTOP", "Hyprland")
os.setenv("XDG_SESSION_DESKTOP", "Hyprland")
os.setenv("XDG_SESSION_TYPE", "wayland")
os.setenv("GRIMBLAST_EDITOR", "swappy -f")

hl.config({ ecosystem = {
    enforce_permissions = true,
    no_update_news = true,
    no_donation_nag = true,
}})

-- █ █▄░█ █▀█ █░█ ▀█▀
-- █ █░▀█ █▀▀ █▄█ ░█░

-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({ input = {
    kb_layout = "us",
    follow_mouse = 1,

    touchpad = {
        natural_scroll = false,
    },

    sensitivity = 0,
    numlock_by_default = true,
}})

hl.config({ cursor = {
    no_hardware_cursors = 2,
    no_warps = false,
    persistent_warps = true,
    hotspot_padding = 0,
}})

-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.gesture({ fingers = 3, direction = "right", action = "workspace", arg = "+1" })
hl.gesture({ fingers = 3, direction = "left", action = "workspace", arg = "-1" })


-- █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
-- █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/

hl.config({ dwindle = {
    pseudotile = true,
    preserve_split = true,
}})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

hl.config({ master = {
    new_status = "master",
}})

-- █▀▄▀█ █ █▀ █▀▀
-- █░▀░█ █ ▄█ █▄▄

-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({ misc = {
    vrr = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
}})

hl.config({ xwayland = {
    force_zero_scaling = true,
}})

hl.config({ ecosystem = {
    no_update_news = true,
}})

hl.config({ plugin = {
    hyprexpo = {
        columns = 3,
        gap_size = 5,
        bg_col = "rgb(111111)",
        workspace_method = "center current", -- [center/first] [workspace] e.g. first 1 or center m+1
        gesture_distance = 300,               -- how far is the "max" for the gesture
        ["hyprexpo-gesture"] = "3, vertical , expo",
    },
}})

-- █▀ █▀█ █░█ █▀█ █▀▀ █▀▀
-- ▄█ █▄█ █▄█ █▀▄ █▄▄ ██▄

local config_dir = os.getenv("HOME") .. "/.config/hypr"

dofile(config_dir .. "/animations.lua")
dofile(config_dir .. "/keybindings.lua")
dofile(config_dir .. "/windowrules.lua")
dofile(config_dir .. "/themes/common.lua")        -- shared theme settings
dofile(config_dir .. "/themes/theme.lua")         -- theme specific settings
-- dofile(config_dir .. "/themes/colors.lua")      -- wallbash color override
local colors_f = io.open(config_dir .. "/themes/colors.lua", "r")
if colors_f then colors_f:close(); dofile(config_dir .. "/themes/colors.lua") end
dofile(config_dir .. "/userprefs.lua")
dofile(config_dir .. "/monitors.lua")
dofile(config_dir .. "/permissions.lua")
-- load hostname-specific config
local hostname = io.popen("hostname"):read("*l")
local profile = config_dir .. "/profiles/" .. hostname .. ".lua"
local f = io.open(profile, "r")
if f then f:close(); dofile(profile) end
