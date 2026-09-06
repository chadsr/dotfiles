# Sway aspect — sway config, swayidle, swaylock, sway helper scripts.
# The sway config is loaded via extraConfig (readFile of the authored config);
# swayidle via the HM module; swaylock config + scripts deployed as store-managed
# files. sway-session.target is auto-created by HM's sway module (systemd.enable).
{ den, ... }:
{
  den.aspects.sway = {
    provides.to-users.homeManager =
      { config, ... }:
      {
        wayland.windowManager.sway = {
          enable = true;
          config = { };
          extraConfig = builtins.readFile (config.dots.src "sway/.config/sway/config");
        };

        services.swayidle.enable = true;

        # swaylock config.
        home.file.".config/swaylock/config".source = config.dots.src "sway/.config/swaylock/config";

        # Sway helper scripts (referenced by the sway config).
        home.file.".local/bin/rotate-display".source = config.dots.src "sway/.local/bin/rotate-display";
        home.file.".local/bin/screenshot".source = config.dots.src "sway/.local/bin/screenshot";
        home.file.".local/bin/screenshot-active".source =
          config.dots.src "sway/.local/bin/screenshot-active";
        home.file.".local/bin/screenshot-crop".source = config.dots.src "sway/.local/bin/screenshot-crop";
        home.file.".local/bin/sway-adaptive-sync".source =
          config.dots.src "sway/.local/bin/sway-adaptive-sync";
        home.file.".local/bin/swaylock-corrupt".source = config.dots.src "sway/.local/bin/swaylock-corrupt";
      };
  };
}
