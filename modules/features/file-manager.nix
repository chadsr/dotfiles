# File-manager aspect
{ den, ... }:
{
  den.aspects.file-manager = {
    nixos =
      { pkgs, ... }:
      {
        programs.thunar = {
          enable = true;
          plugins = with pkgs.xfce; [
            thunar-media-tags-plugin
          ];
        };
        environment.systemPackages = with pkgs; [
          thunar-archive-plugin
          thunar-volman
          file-roller
          yazi
        ];
        services.gvfs.enable = true;
        services.tumbler.enable = true;
      };

    provides.to-users.homeManager =
      { config, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        # Mutable thunar state (rewritten by thunar at runtime).
        xdg.configFile."Thunar/uca.xml".source = config.dots.link "thunar/.config/Thunar/uca.xml";
        xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source =
          config.dots.link "thunar/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml";
      };
  };
}
