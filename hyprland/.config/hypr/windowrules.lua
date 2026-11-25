-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
  name = "idleinhibit-fullscreen-focus",
  match = { fullscreen = true },
  idle_inhibit = "focus",
})

hl.window_rule({
  name = "single-window",
  border_size = 0,
  match = { workspace = "w[t1]" },
})

hl.window_rule({
  name = "pavucontrol",
  float = true,
  match = { class = "^(org.pulseaudio.pavucontrol)$" },
})

hl.window_rule({
  name = "ghostty.floattui",
  float = true,
  center = true,
  border_size = 2,
  match = { class = "^(ghostty.floattui)$" },
})

hl.window_rule({
  name = "blueman-manager",
  float = true,
  match = { class = "^(blueman-manager)$" },
})

hl.window_rule({
  name = "nm-applet",
  float = true,
  match = { class = "^(nm-applet)$" },
})

hl.window_rule({
  name = "nm-connection-editor",
  float = true,
  match = { class = "^(nm-connection-editor)$" },
})

hl.window_rule({
  name = "kde-authentication-agent",
  float = true,
  match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
})

hl.window_rule({
  name = "gnome-authentication-agent",
  float = true,
  match = { class = "^(polkit-gnome-authentication-agent-1)$" },
})

hl.window_rule({
  name = "dolphin-progress",
  float = true,
  match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" },
})

hl.window_rule({
  name = "dolphin-copying",
  float = true,
  match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" },
})

hl.window_rule({
  name = "clipse",
  float = true,
  size = { 660, 660 },
  match = { class = "^(com.example.clipse)$" },
})

hl.window_rule({
  name = "nextcloud",
  float = true,
  size = { 600, 800 },
  move = { 0, 24 },
  border_size = 0,
  no_anim = true,
  match = { class = "^(com.nextcloud.desktopclient.nextcloud)$", title = "^(Nextcloud)$" },
})

local pinned = {
  classes = "mpv", -- "mpv|vlc"
  titles = "Picture in picture", -- only windows with these titles
  width = 480,
  height = 270,
  margin_x = 10,
  margin_y = 34,
  border = 2,
}

hl.window_rule({
  name = "pinned-class",
  match = { class = "^(" .. pinned.classes .. ")$", pin = true },
  border_size = pinned.border,
  keep_aspect_ratio = true,
  no_anim = true,
})

hl.window_rule({
  name = "pinned-title",
  match = { title = "^(" .. pinned.titles .. ")$", pin = true },
  border_size = pinned.border,
  keep_aspect_ratio = true,
  no_anim = true,
})

hl.on("window.pin", function(w)
  if w == nil or w.monitor == nil or not w.pinned then
    return
  end
  -- Lua patterns have no "|", so test both lists literally
  local by_class = ("|" .. pinned.classes .. "|"):find("|" .. (w.class or "") .. "|", 1, true)
  local by_title = ("|" .. pinned.titles .. "|"):find("|" .. (w.title or "") .. "|", 1, true)
  if not by_class and not by_title then
    return
  end
  hl.dispatch(hl.dsp.window.resize({ window = w, x = pinned.width, y = pinned.height }))
  hl.dispatch(hl.dsp.window.move({
    window = w,
    x = w.monitor.position.x + w.monitor.size.width - pinned.width - pinned.margin_x,
    y = w.monitor.position.y + pinned.margin_y,
  }))
end)

-- █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

hl.layer_rule({
  name = "layerrule-1",
  blur = true,
  ignore_alpha = 0,
  match = { namespace = "rofi" },
})

hl.layer_rule({
  name = "layerrule-2",
  blur = true,
  ignore_alpha = 0,
  match = { namespace = "notifications" },
})

hl.layer_rule({
  name = "layerrule-3",
  blur = true,
  ignore_alpha = 0,
  match = { namespace = "swaync-notification-window" },
})

hl.layer_rule({
  name = "layerrule-4",
  blur = true,
  ignore_alpha = 0,
  match = { namespace = "swaync-control-center" },
})

hl.layer_rule({
  name = "layerrule-5",
  blur = true,
  match = { namespace = "logout_dialog" },
})

hl.layer_rule({
  name = "layerrule-6",
  blur = true,
  match = { namespace = "waybar" },
})
