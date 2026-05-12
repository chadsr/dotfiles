-- █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
-- █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

-- See https://wiki.hypr.land/Configuring/Start/
--  &  https://wiki.hypr.land/Configuring/Basics/Binds/

-- Main modifier
local mainMod = "SUPER" -- super / meta / windows key

-- Assign apps
local term = "ghostty"
local file = term .. " -e yazi"
local browser = "librewolf"
local menu = "fuzzel"

-- Window/Session actions
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exit()) -- kill hyprland session
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" })) -- toggle the window between focus and float
hl.bind(mainMod .. " + G", hl.dsp.group.toggle()) -- toggle the window between focus and group
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- toggle the window between focus and fullscreen
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock")) -- launch lock screen
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + grave", function()
    hl.plugin.hyprexpo.expo("toggle")
end)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color Picker" }) -- Pick color (Hex) >> clipboard#
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && systemctl --user restart waybar"))

-- Application shortcuts
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term .. " +new-window")) -- launch terminal emulator
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(file)) -- launch file manager
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser)) -- launch web browser
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(menu)) -- launch menu
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(term .. " --class=com.example.clipse -e clipse")) -- launch clipse
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw")) -- show/hide swaync

-- Audio control
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true }) -- toggle audio mute
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true }) -- toggle microphone mute
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume -5"),
    { locked = true, repeating = true }
) -- decrease volume
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume +5"),
    { locked = true, repeating = true }
) -- increase volume

-- Media control
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- toggle between media play and pause
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- toggle between media play and pause
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true }) -- media next
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true }) -- media previous
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("hypr-gamemode"))

-- Brightness control
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +5"), { locked = true, repeating = true }) -- increase brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -5"), { locked = true, repeating = true }) -- decrease brightness
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("sunsetr preset day")) -- toggle between day preset and default config

-- Move between grouped windows
hl.bind(mainMod .. " + CTRL + H", hl.dsp.group.prev())
hl.bind(mainMod .. " + CTRL + L", hl.dsp.group.next())

-- Screenshot/Screencapture
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copysave screen"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("grimblast --notify copysave area"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("grimblast --notify copysave active"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast edit screen"))
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd("grimblast edit area"))
hl.bind("ALT + SHIFT + Print", hl.dsp.exec_cmd("grimblast edit active"))

-- Move/Change window focus
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + Tab", hl.dsp.focus({ direction = "d" }))

-- Switch workspaces
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Switch workspaces to a relative workspace
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.focus({ workspace = "r-1" }))

-- Move to the first empty workspace
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.focus({ workspace = "empty" }))

-- Resize windows
hl.bind(mainMod .. " + R", hl.dsp.window.resize(), { repeating = true })

-- Move focused window to a workspace
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Move active window around current workspace with mainMod + SHIFT [←→↑↓]
local moveactivewindow =
    'grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'
hl.bind(
    mainMod .. " + SHIFT + Left",
    hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"),
    { repeating = true, description = "Move activewindow to the left" }
)
hl.bind(
    mainMod .. " + SHIFT + Right",
    hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"),
    { repeating = true, description = "Move activewindow to the right" }
)
hl.bind(
    mainMod .. " + SHIFT + Up",
    hl.dsp.exec_cmd(moveactivewindow .. " 0 -30 || hyprctl dispatch movewindow u"),
    { repeating = true, description = "Move activewindow up" }
)
hl.bind(
    mainMod .. " + SHIFT + Down",
    hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"),
    { repeating = true, description = "Move activewindow down" }
)

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/Resize focused window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + Z", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + R", hl.dsp.window.resize(), { mouse = true })

-- Move/Switch to special workspace (scratchpad)
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special())

-- Toggle focused window split
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("togglesplit"))

-- Move focused window to a workspace silently
hl.bind(mainMod .. " + ALT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind(mainMod .. " + ALT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind(mainMod .. " + ALT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind(mainMod .. " + ALT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind(mainMod .. " + ALT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind(mainMod .. " + ALT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
hl.bind(mainMod .. " + ALT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))
hl.bind(mainMod .. " + ALT + 8", hl.dsp.window.move({ workspace = 8, follow = false }))
hl.bind(mainMod .. " + ALT + 9", hl.dsp.window.move({ workspace = 9, follow = false }))
hl.bind(mainMod .. " + ALT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))
