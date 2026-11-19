herdr.caps { agents_per_run = 0, tokens_per_day = 0, wall_time = "1m" }

herdr.every("1m", { name = "sheprd-mux-link" }, function()
  sh("$HOME/.local/bin/sheprd-mux-link", { check = false, timeout = "30s" })
end)
