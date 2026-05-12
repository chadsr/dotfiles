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
	name = "bluetuith",
	float = true,
	match = { class = "^(ghostty)$", title = "^(bluetuith)$" },
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
