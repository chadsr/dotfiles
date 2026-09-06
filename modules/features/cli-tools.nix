# CLI tools aspect - standalone CLI packages (bat, wget, curl, dua, etc.).
{ den, ... }:
{
  den.aspects.cli-tools = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        home.packages = with pkgs; [
          bat
          calibre
          curl
          dua
          fd
          file
          fzf
          gh
          htop
          jq
          killall
          lm_sensors
          mtr
          nano
          nmap
          ripgrep
          smartmontools
          sshfs
          traceroute
          unzip
          wget
          which
          yq
          zip
          zoxide
        ];
      };
  };
}
