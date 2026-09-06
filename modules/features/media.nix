# Media aspect - mpv, cava, jellyfin, freetube, tidal-hifi, gallery-dl, yt-dlp,
# qbittorrent. Store-managed authored configs; the program-rewritten paths
# (freetube settings.db) are two-way via mkOutOfStoreSymlink. Secret paths
# (tidal-hifi, gallery-dl, qBittorrent.conf) are owned by sops (secrets aspect).
{ den, ... }:
{
  den.aspects.media = {
    includes = [
      # tidal-hifi — free-licensed but builds against the unfree castlabs-electron
      (den.batteries.unfree [
        "tidal-hifi"
        "castlabs-electron"
      ])
      # gyroflow — pulls mdk-sdk (unfree video SDK) as a build dependency
      (den.batteries.unfree [ "mdk-sdk" ])
    ];
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        home.packages = with pkgs; [
          mpv
          cava
          freetube
          tidal-hifi
          gallery-dl
          yt-dlp
          qbittorrent
          jellyfin-media-player
          gyroflow
        ];

        # Authored configs.
        xdg.configFile."mpv".source = config.dots.src "mpv/.config/mpv";
        xdg.configFile."cava".source = config.dots.src "cava/.config/cava";
        xdg.configFile."yt-dlp/config".source = config.dots.src "yt-dlp/.config/yt-dlp/config";
        # jellyfin-mpv-shim conf.json is program-rewritten → two-way.
        xdg.configFile."jellyfin-mpv-shim/conf.json".source =
          config.dots.link "jellyfin/.config/jellyfin-mpv-shim/conf.json";

        # Mutable: freetube settings.db (Cache/Cookies/leveldb are gitignored).
        home.file.".config/FreeTube/settings.db".source =
          config.dots.link "freetube/.config/FreeTube/settings.db";
      };
  };
}
