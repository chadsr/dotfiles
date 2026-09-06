# Desktop aspect skeleton (full WM/terminal/launcher config lands in tasks
# 2.7/3.9). Demonstrates the `provides.to-users.homeManager` pattern: the host
# delivers a baseline Home Manager environment to all of its users.
{ den, ... }:
{
  den.aspects.desktop = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        # Baseline session packages delivered to every user on a desktop host.
        home.packages = [ pkgs.hello ];

        # XDG default application associations (rewritten by the desktop at runtime).
        xdg.configFile."mimeapps.list".source = config.dots.link "xdg/.config/mimeapps.list";

        # The former mk_dirs set (setup.sh:396-430) that are not already created
        # as parents of managed files. HM auto-creates parents of home.file
        # targets; these standalone dirs need an explicit .keep marker.
        home.file = {
          ".cargo/.keep".text = "";
          ".continue/.keep".text = "";
          ".icons/.keep".text = "";
          ".local/share/applications/.keep".text = "";
          ".local/share/fonts/OTF/.keep".text = "";
          ".local/share/fonts/TTF/.keep".text = "";
          ".nvm/alias/.keep".text = "";
          ".radicle/keys/.keep".text = "";
          ".themes/.keep".text = "";
          ".vscode-oss/.keep".text = "";
          "Pictures/Backgrounds/.keep".text = "";
        };
      };
  };
}
