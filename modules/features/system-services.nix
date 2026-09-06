# System-services aspect - background desktop plumbing + maintenance services
# (smartd+notify, clamav freshclam, fstrim, btrfs autoScrub, udisks2, gvfs,
# tumbler, input-remapper, gnome-keyring secret service, enable-linger).
{ den, ... }:
{
  den.aspects.system-services = {
    nixos =
      { pkgs, lib, ... }:
      {
        # Thunderbolt auto-authorization (no-op without a TB controller).
        services.hardware.bolt.enable = true;

        # i2c / DDC-CI for external-monitor control (coolercontrol/lact/ddcutil).
        hardware.i2c.enable = true;

        # Firmware updates (fwupd), power management (upower), dconf (gsettings).
        services.fwupd.enable = true;
        services.upower.enable = true;
        programs.dconf.enable = true;

        # btrfs maintenance tools (for the disko btrfs layout).
        # (merged with the smartdnotify script package below)

        # SSD TRIM timer.
        services.fstrim.enable = true;

        # btrfs scrub (ties to the disko btrfs layout).
        services.btrfs.autoScrub = {
          enable = true;
          fileSystems = [
            "/"
            "/nix"
            "/home"
          ];
        };

        # Thunar/thunar-volman USB automount.
        services.udisks2.enable = true;

        # Secret service (NM Wi-Fi passwords / app secrets); SSH-agent role off.
        services.gnome.gnome-keyring.enable = true;

        # SMART monitoring + notification.
        services.smartd = {
          enable = true;
          autodetect = true;
          notifications = {
            mail.enable = false;
            test = true;
            wall.enable = false;
          };
        };

        # smartd warning notifier (translated from the former
        # system/common/usr/share/smartmontools/smartd_warning.d/smartdnotify).
        environment.systemPackages = [
          pkgs.btrfs-progs
          (pkgs.writeShellScriptBin "smartdnotify" ''
            ${pkgs.libnotify}/bin/notify-send -u critical "SMART error ($SMARTD_FAILTYPE)" "$SMARTD_MESSAGE"
          '')
        ];

        # ClamAV freshclam.
        services.clamav.daemon.enable = lib.mkDefault false;
        services.clamav.updater.enable = lib.mkDefault true;

        # Input remapper (per-device key remapping).
        services.input-remapper.enable = true;

        # swayosd system-level input daemon (the user-level swayosd-server
        # connects to this for input events).
        systemd.services.swayosd-libinput-backend = {
          description = "SwayOSD LibInput backend";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            Restart = "on-failure";
            ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
          };
        };

        # Keep marvin's user services running without an active login session.
        system.activationScripts.enable-linger = ''
          ${pkgs.shadow}/bin/loginctl enable-linger marvin 2>/dev/null || true
        '';

        # Keep marvin's user services running without an active login session.
        systemd.services."user@".enable = true;
      };
  };
}
