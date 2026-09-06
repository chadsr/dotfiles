# Audio aspect - pipewire + rtkit + @audio PAM limits (nixos); pavucontrol.ini
# and pipewire.conf/pulse client are user-managed, pavucontrol.ini mutable.
{ den, ... }:
{
  den.aspects.audio = {
    nixos =
      { lib, ... }:
      {
        # rtkit for realtime scheduling; pipewire replaces pulseaudio.
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
        # sound/hardware.pulseaudio stay unset (pipewire-only) per design D14.

        # Realtime audio priorities (@audio group).
        security.pam.loginLimits = [
          {
            domain = "@audio";
            item = "rtprio";
            type = "-";
            value = 95;
          }
          {
            domain = "@audio";
            item = "memlock";
            type = "-";
            value = "unlimited";
          }
        ];
      };

    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        home.packages = [
          pkgs.pavucontrol
          pkgs.easyeffects
        ];
        # pipewire configs (store-managed).
        xdg.configFile."pipewire/pipewire.conf".source =
          config.dots.src "pipewire/.config/pipewire/pipewire.conf";
        xdg.configFile."pulse/client.conf".source = config.dots.src "pipewire/.config/pulse/client.conf";
        xdg.configFile."pulseaudio-ctl/config".source =
          config.dots.src "pipewire/.config/pulseaudio-ctl/config";
        # pavucontrol.ini is rewritten at runtime -> two-way.
        xdg.configFile."pavucontrol.ini".source = config.dots.link "pipewire/.config/pavucontrol.ini";
      };
  };
}
