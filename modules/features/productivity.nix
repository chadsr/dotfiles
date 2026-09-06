# Productivity aspect - logseq, todoman, superproductivity, khal, vdirsyncer,
# nextcloud, cura. Configs that are secret (khal, vdirsyncer, nextcloud) are
# owned by sops; logseq configs mutable (two-way). Sync timers on nixos.
{ den, ... }:
{
  den.aspects.productivity = {
    includes = [
      (den.batteries.insecure [ "electron-39.8.10" ])
      # beeper — unfree (proprietary license)
      (den.batteries.unfree [ "beeper" ])
    ];
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        home.packages = with pkgs; [
          logseq
          todoman
          super-productivity
          khal
          vdirsyncer
          nextcloud-client
          evolution
          beeper
        ];

        # Authored productivity configs (store-managed).
        xdg.configFile."todoman/config.py".source = config.dots.src "todoman/.config/todoman/config.py";

        # Mutable logseq state (two-way).
        xdg.configFile."Logseq/Preferences".source = config.dots.link "logseq/.config/Logseq/Preferences";
        xdg.configFile."Logseq/configs.edn".source = config.dots.link "logseq/.config/Logseq/configs.edn";
        home.file.".logseq/config/config.edn".source = config.dots.link "logseq/.logseq/config/config.edn";
        xdg.configFile."logseq-flags.conf".source = config.dots.src "logseq/.config/logseq-flags.conf";

        # vdirsyncer sync service + timer (calendar/contacts sync).
        systemd.user.services.vdirsyncer-sync = {
          Unit = {
            Description = "Sync vdirsyncer";
            Wants = [ "network-online.target" ];
            After = [
              "network-online.target"
              "nss-lookup.target"
            ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
          };
        };
        systemd.user.timers.vdirsyncer-sync = {
          Timer = {
            OnBootSec = "5min";
          };
          Install.WantedBy = [ "timers.target" ];
        };

        # nextcloud-client service (background sync).
        systemd.user.services.nextcloud-client = {
          Unit = {
            Description = "Nextcloud Desktop Client";
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            Restart = "on-failure";
            RestartSec = 3;
            ExecStart = "${pkgs.nextcloud-client}/bin/nextcloud --background";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
