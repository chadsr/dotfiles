# thinky host aspect (Arch laptop -> NixOS). Includes the shared Linux desktop
# composite plus the laptop-only battery aspect (TLP + batsignal). Remaining
# laptop-specific concerns: thermald, TrackPoint, fprintd PAM, tablet-rotate.
{ den, ... }:
{
  den.aspects.thinky = {
    includes = [
      den.aspects.desktop-linux
      den.aspects.battery
    ];

    nixos =
      { pkgs, ... }:
      {
        # Intel thermal daemon.
        services.thermald.enable = true;

        # TrackPoint.
        hardware.trackpoint.enable = true;

        # fprintd fingerprint PAM auth for sudo + system-local-login (4.2).
        services.fprintd.enable = true;
        security.pam.services.sudo.fprintAuth = true;
        security.pam.services.system-local-login.fprintAuth = true;

        environment.systemPackages = [
          pkgs.powertop
          pkgs.acpid
        ];
        services.acpid.enable = true;

        # powertop auto-tune service (thinky only).
        systemd.services.powertop = {
          description = "Powertop auto-tune";
          after = [ "multi-user.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.powertop}/bin/powertop --auto-tune";
          };
        };
      };

    # tablet-rotate script + service (thinky-only laptop feature).
    provides.to-users.homeManager =
      { config, ... }:
      {
        home.file.".local/bin/tablet-rotate".source = config.dots.src "scripts/.local/bin/tablet-rotate";

        systemd.user.services.tablet-rotate = {
          Unit = {
            Description = "Rotate display when device enters tablet mode";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 1;
            ExecStart = "%h/.local/bin/tablet-rotate";
          };
          Install.WantedBy = [
            "sway-session.target"
            "hypr-session.target"
          ];
        };
      };
  };
}
