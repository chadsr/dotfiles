# Hyprland aspect — hyprland config (*.lua modules), hypridle, hyprlock,
# hypr-gamemode, hypr-sunsetr, session target, catppuccin theme.
#
# The lua entry point (hyprland.lua) uses require() to load sibling modules, so
# every file must be present in ~/.config/hypr/. They are deployed individually
# (NOT as a whole-directory symlink) so HM's generated hyprland.conf can coexist.
{ den, ... }:
{
  den.aspects.hyprland = {
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        hypr = config.dots.src "hyprland/.config/hypr";
        # Deploy individual files from the store directory so HM's generated
        # hyprland.conf can coexist (a whole-directory xdg.configFile."hypr"
        # would conflict with it).
        deployHyprFile = name: {
          name = "hypr/${name}";
          value.source = hypr + "/${name}";
        };
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          settings.source = [ "${hypr}/hyprland.lua" ];
        };

        services.hypridle.enable = true;
        programs.hyprlock.enable = true;

        home.packages = with pkgs; [
          hyprpicker
          sunsetr
        ];

        # Individual hypr config files + sunsetr configs (merged).
        xdg.configFile =
          (builtins.listToAttrs (
            map deployHyprFile [
              "animations.lua"
              "keybindings.lua"
              "monitors.lua"
              "permissions.lua"
              "windowrules.lua"
              "profiles/shifty.lua"
              "profiles/thinky.lua"
              "themes/common.lua"
              "themes/theme.lua"
              "hypridle.conf"
              "hyprlock.conf"
            ]
          ))
          // {
            "sunsetr/sunsetr.toml".source = config.dots.src "hyprland/.config/sunsetr/sunsetr.toml";
            "sunsetr/presets/day/sunsetr.toml".source =
              config.dots.src "hyprland/.config/sunsetr/presets/day/sunsetr.toml";
          };

        # hypr-gamemode script.
        home.file.".local/bin/hypr-gamemode".source = config.dots.src "hyprland/.local/bin/hypr-gamemode";

        # hypr-sunsetr service + sunsetr configs.
        systemd.user.services.hypr-sunsetr = {
          Unit = {
            Description = "Sunsetr";
            PartOf = [ "graphical-session.target" ];
            Requires = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.sunsetr}/bin/sunsetr";
            Restart = "on-failure";
            RestartSec = 30;
          };
          Install.WantedBy = [ "hypr-session.target" ];
        };
      };
  };
}
