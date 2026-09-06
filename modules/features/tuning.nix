# Tuning aspect — cooling/GPU/colour tooling: CoolerControl + LACT +
# liquidctl daemons and the Dell S3422DWG ICC profile via colord. The CachyOS
# kernel, amdgpu ppfeaturemask, ntsync, and power-profiles-daemon are host-level
# (they live in the shifty host aspect / the gaming aspect). Included only by the
# shifty host aspect (NOT the shared desktop composite).
{ den, ... }:
{
  den.aspects.tuning = {
    nixos =
      { pkgs, lib, ... }:
      {
        # liquidctl udev rule.
        services.udev.packages = [ pkgs.liquidctl ];

        # CoolerControl + LACT daemons (no nixpkgs service module; explicit units).
        systemd.services.lactd = {
          description = "LACT GPU control daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.lact}/bin/lact daemon";
            Restart = "on-failure";
          };
        };
        systemd.services.coolercontrold = {
          description = "CoolerControl daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.coolercontrol.coolercontrold}/bin/coolercontrold";
            Restart = "on-failure";
          };
        };

        # ICC colour profile + colord live in the shifty host aspect (monitor-
        # specific hardware config), not here.
        environment.systemPackages = with pkgs; [
          liquidctl
          coolercontrol.coolercontrol-gui
          lact
          proton-cachyos
          proton-ge-custom
        ];
      };

    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        # CoolerControl GUI launcher (user service; the daemon is a system unit).
        systemd.user.services.coolercontrol = {
          Unit = {
            Description = "CoolerControl GUI";
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "on-failure";
            RestartSec = "1s";
            ExecStart = "${pkgs.coolercontrol.coolercontrol-gui}/bin/coolercontrol";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # liquidctl: initialize + logo/ring lighting (oneshot per session).
        systemd.user.services.liquidctl = {
          Unit = {
            Description = "Liquidctl";
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "5s";
            ExecStart = [
              "${pkgs.liquidctl}/bin/liquidctl initialize all"
              "${pkgs.liquidctl}/bin/liquidctl set logo color off"
              "${pkgs.liquidctl}/bin/liquidctl set ring color water-cooler --speed slowest 000000 8800ff"
            ];
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
