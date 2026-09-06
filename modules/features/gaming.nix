# Gaming aspect — steam, gamemode, mangohud, heroic, gamescope. Shared across
# the Linux desktop hosts (thinky + shifty); included via the desktop-linux
# composite. Proton is shifty-only (CachyOS/GE via Chaotic Nyx) and lives in the
# tuning aspect.
{ den, ... }:
{
  den.aspects.gaming = {
    includes = [
      # steam — unfree (Valve proprietary license); includes steam-unwrapped etc.
      (den.batteries.unfree [
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ])
      # heroic bundles electron_39 (insecure/EOL).
      (den.batteries.insecure [ "electron-39.8.10" ])
    ];
    nixos =
      { pkgs, ... }:
      {
        # ntsync: fast Windows mutex emulation for wine/proton.
        boot.kernelModules = [ "ntsync" ];
        programs.steam.enable = true;
        programs.gamemode.enable = true;
        environment.systemPackages = [
          pkgs.mangohud
          pkgs.heroic
          pkgs.gamescope
        ];
      };

    provides.to-users.homeManager =
      { config, ... }:
      {
        # Gaming runtime configs (store-managed authored).
        xdg.configFile."gamemode.ini".source = config.dots.src "gamemode/.config/gamemode.ini";
        xdg.configFile."MangoHud/MangoHud.conf".source =
          config.dots.src "mangohud/.config/MangoHud/MangoHud.conf";
        home.file.".steam/steam/steam_dev.cfg".source = config.dots.src "steam/.steam/steam/steam_dev.cfg";
      };
  };
}
