# Compositor aspect - shared Wayland session base: hyprland+sway NixOS modules,
# portals, ly display manager, polkit (lxqt-policykit-agent), terminals, launchers,
# session utils, and the waybar bar config. Session targets delivered to users.
{ den, ... }:
{
  den.aspects.compositor = {
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland.enable = true;
        programs.sway.enable = true;

        # Portals for Wayland screen-share / file dialogs.
        xdg.portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-hyprland
          ];
        };

        # ly display manager — behavioral settings translated from the former
        # system/common/etc/ly/config.ini (the bulk of that file is cosmetic
        # colormix-animation defaults; these are the login-experience values).
        services.displayManager.ly = {
          enable = true;
          settings = {
            animation = "colormix";
            animation_frame_delay = 5;
            asterisk = "*";
            auth_fails = 10;
            clock = "%c";
            hide_borders = true;
            blank_box = true;
            brightness_down_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s 10%-";
            brightness_down_key = "F5";
            brightness_up_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s +10%";
            brightness_up_key = "F6";
          };
        };

        # Polkit agent package (the agent itself is started as a user unit below).
        environment.systemPackages = with pkgs; [ lxqt.lxqt-policykit ];

        services.gnome.gcr-ssh-agent.enable = false;
      };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        repo = config.dotfilesRepo;
      in
      {
        home.packages = with pkgs; [
          alacritty
          ghostty
          fuzzel
          wlogout
          clipse
          swayosd
          swaynotificationcenter
          solaar
          gpu-screen-recorder
          wl-clipboard
          grim
          slurp
          satty
          mako
          dunst
          kanshi
          btop
          bat
          awww
          xsettingsd
          grimblast
          gpu-screen-recorder-gtk
          (pkgs.callPackage ../../packages/waybar-crypto.nix { })
        ];

        # awww wallpaper: background + the random-multi script + session units.
        home.file."Pictures/Backgrounds/background.png".source =
          config.dots.src "awww/Pictures/Backgrounds/background.png";
        home.file.".local/bin/awww_random_multi".source =
          config.dots.src "awww/.local/bin/awww_random_multi";
        systemd.user.services.awww-daemon = {
          Unit = {
            Description = "AWWW wallpaper daemon";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStart = "${pkgs.awww}/bin/awww-daemon";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
        systemd.user.services.awww-random = {
          Unit = {
            Description = "AWWW randomized wallpapers";
            PartOf = [ "graphical-session.target" ];
            After = [
              "graphical-session.target"
              "awww-daemon.service"
            ];
            Requires = [ "awww-daemon.service" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStart = "%h/.local/bin/awww_random_multi %h/Pictures/Backgrounds crop wave 300";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };

        # Authored session configs (store-managed).
        programs.alacritty.enable = true;
        xdg.configFile."alacritty".source = config.dots.src "alacritty/.config/alacritty";
        xdg.configFile."ghostty".source = config.dots.src "ghostty/.config/ghostty";
        xdg.configFile."fuzzel".source = config.dots.src "fuzzel/.config/fuzzel";
        xdg.configFile."wlogout".source = config.dots.src "wlogout/.config/wlogout";
        xdg.configFile."swayosd/config.toml".source = config.dots.src "swayosd/.config/swayosd/config.toml";
        xdg.configFile."swaync".source = config.dots.src "swaync/.config/swaync";
        xdg.configFile."dunst/dunstrc".source = config.dots.src "dunst/.config/dunst/dunstrc";
        xdg.configFile."kanshi/config".source = config.dots.src "kanshi/.config/kanshi/config";
        xdg.configFile."mako/config".source = config.dots.src "mako/.config/mako/config";
        xdg.configFile."gammastep".source = config.dots.src "gammastep/.config/gammastep";
        xdg.configFile."gpu-screen-recorder".source =
          config.dots.src "gpu-screen-recorder/.config/gpu-screen-recorder";
        xdg.configFile."espanso".source = config.dots.src "espanso/.config/espanso";

        # waybar - config.jsonc is JSONC (has comments), deployed via source;
        # style.css is gitignored (built at runtime). cavaSupport pinned (7.1a).
        programs.waybar = {
          enable = true;
          package = pkgs.waybar.override { cavaSupport = true; };
        };
        xdg.configFile."waybar/config.jsonc".source = config.dots.src "waybar/.config/waybar/config.jsonc";

        # Mutable session state (two-way into the repo).
        xdg.configFile."solaar/config.yaml".source = config.dots.link "solaar/.config/solaar/config.yaml";
        xdg.configFile."solaar/rules.yaml".source = config.dots.link "solaar/.config/solaar/rules.yaml";
        xdg.configFile."gpu-screen-recorder/config".source =
          config.dots.link "gpu-screen-recorder/.config/gpu-screen-recorder/config";
        xdg.configFile."gpu-screen-recorder/config_ui".source =
          config.dots.link "gpu-screen-recorder/.config/gpu-screen-recorder/config_ui";
        xdg.configFile."clipse/config.json".source = config.dots.link "clipse/.config/clipse/config.json";
        xdg.configFile."clipse/custom_theme.json".source =
          config.dots.link "clipse/.config/clipse/custom_theme.json";
        xdg.configFile."btop/btop.conf".source = config.dots.link "btop/.config/btop/btop.conf";
        xdg.configFile."input-remapper-2/config.json".source =
          config.dots.link "input-remapper/.config/input-remapper-2/config.json";
        xdg.configFile."input-remapper-2/xmodmap.json".source =
          config.dots.link "input-remapper/.config/input-remapper-2/xmodmap.json";
        xdg.configFile."input-remapper-2/presets".source =
          config.dots.link "input-remapper/.config/input-remapper-2/presets";
        xdg.configFile."lact/ui.yaml".source = config.dots.link "lact/.config/lact/ui.yaml";
        xdg.configFile."lact/profiles".source = config.dots.link "lact/.config/lact/profiles";

        # btop binary + bat config + scripts.
        xdg.configFile."bat/config".source = config.dots.src "bat/.config/bat/config";
        # satty (screenshot editor) config.
        xdg.configFile."satty/config.toml".source = config.dots.src "satty/.config/satty/config.toml";

        # wlr-sunclock desktop widget (only emitted if the package is in nixpkgs).
        systemd.user.services.wlr-sunclock = lib.optionalAttrs (pkgs ? "wlr-sunclock") {
          Unit = {
            Description = "Wlr-Sunclock";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStart = "${lib.getExe pkgs."wlr-sunclock"} --width 200 --layer bottom --anchors tr --colour-ocean \"#1e1e2e\" --colour-land \"#cba6f7\"";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
        home.file.".local/bin/delogout".source = config.dots.src "scripts/.local/bin/delogout";
        home.file.".local/bin/screenlock".source = config.dots.src "scripts/.local/bin/screenlock";

        # Polkit auth agent — start lxqt-policykit-agent on the Wayland session
        # so privilege-elevation prompts appear (spec: system-configuration).
        systemd.user.services.lxqt-policykit-agent = {
          Unit = {
            Description = "lxqt-policykit-agent";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # hypr-session.target — declared so services that WantedBy it resolve.
        # Matches the original dots/ definition exactly (BindsTo graphical-session,
        # Wants/After graphical-session-pre for correct startup ordering).
        systemd.user.targets.hypr-session = {
          Unit = {
            Description = "hyprland compositor session";
            Documentation = "man:systemd.special(7)";
            BindsTo = [ "graphical-session.target" ];
            Wants = [ "graphical-session-pre.target" ];
            After = [ "graphical-session-pre.target" ];
          };
        };

        # --- Session services ---
        # kanshi uses the HM module; the rest are inline (no HM module exists).
        services.kanshi = {
          enable = true;
          systemdTarget = "graphical-session.target";
        };

        systemd.user.services.swayosd = {
          Unit = {
            Description = "SwayOSD";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
        systemd.user.services.swaync = {
          Unit = {
            Description = "SwayNC";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
        systemd.user.services.clipse = {
          Unit = {
            Description = "Clipse listener";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.clipse}/bin/clipse -listen";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
        systemd.user.services.xsettingsd = {
          Unit = {
            Description = "XSETTINGS-protocol daemon";
            BindsTo = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd";
            Slice = "session.slice";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
        systemd.user.services.setup-temps = {
          Unit = {
            Description = "Symlink temperatures to /tmp";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "%h/.local/bin/setup-temps.sh";
          };
          Install.WantedBy = [ "default.target" ];
        };

        # waybar style.css + custom modules (tracked; mkForce wins over catppuccin's
        # auto-generated waybar styling, which would clobber the custom layout).
        xdg.configFile."waybar/style.css".source = lib.mkForce (
          config.dots.src "waybar/.config/waybar/style.css"
        );
        xdg.configFile."waybar/modules".source = config.dots.src "waybar/.config/waybar/modules";

        # setup-temps.sh script (symlinks hwmon temp files to /tmp for waybar).
        home.file.".local/bin/setup-temps.sh".source = config.dots.src "waybar/.local/bin/setup-temps.sh";

        # fuzzel dmenu wrapper.
        home.file.".local/bin/dmenu".source = config.dots.src "fuzzel/.local/bin/dmenu";
      };
  };
}
