# Theming aspect - catppuccin (mocha) via the catppuccin flake, fonts, cursor
# (hackneyed derivation - task 7.2), kvantum/sweet/candy themes, gtk/qt settings,
# xsettingsd. kdeglobals mutable (two-way).
{ inputs, den, ... }:
{
  den.aspects.theming = {
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        repo = config.dotfilesRepo;
        # cryptofont (not in nixpkgs) fetched from upstream, replacing the former
        # git submodule symlink at modules/dots/fonts/.../cryptofont.ttf.
        cryptofont = pkgs.fetchFromGitHub {
          owner = "Cryptofonts";
          repo = "cryptofont";
          rev = "01ebf56c40d9578e55957dc873027ae3055844c2";
          hash = "sha256-4HTjTYbkiw42ZB6RHj8Cd2FUE0Rxs0fbKBHUUvXodxc=";
          sparseCheckout = [ "fonts" ];
        };
      in
      {
        # catppuccin home-manager module from the catppuccin flake.
        imports = [ inputs.catppuccin.homeModules.catppuccin ];
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "mauve";
        };

        # Fonts: nerd fonts (nixpkgs) + cryptofont (fetched).
        home.packages = [ pkgs.nerd-fonts.hack ];
        home.file.".local/share/fonts/TTF/cryptofont.ttf".source = "${cryptofont}/fonts/cryptofont.ttf";

        # GTK/Qt settings. Sweet theme via the nixpkgs sweet-nova package.
        gtk = {
          enable = true;
          # catppuccin.enable themes the CLI apps (bat/btop/helix/etc.); GTK stays
          # Sweet + candy-icons per the spec — mkForce wins over catppuccin's gtk.
          theme = lib.mkForce {
            name = "Sweet-Dark";
            package = pkgs.sweet-nova;
          };
          iconTheme = lib.mkForce {
            name = "candy-icons";
            package = pkgs.candy-icons;
          };
          cursorTheme = {
            # nixpkgs `hackneyed` builds the light theme by default; override it to
            # pass DARK_THEME=1, which the Makefile uses to produce Hackneyed-Dark.
            name = "Hackneyed-Dark";
            package = pkgs.hackneyed.overrideAttrs (prev: {
              makeFlags = prev.makeFlags ++ [ "DARK_THEME=1" ];
            });
          };
        };
        # Deploy the theme/icon assets to their former target paths for non-GTK
        # apps that read the dirs directly.
        home.file.".themes/Sweet".source = "${pkgs.sweet-nova}/share/themes";
        home.file.".icons/candy-icons".source = "${pkgs.candy-icons}/share/icons/candy-icons";
        qt = {
          enable = true;
          platformTheme.name = "qt6ct";
          style.name = "kvantum";
        };

        # Authored theme configs (store-managed).
        xdg.configFile."Kvantum/kvantum.kvconfig".source =
          config.dots.src "qt/.config/Kvantum/kvantum.kvconfig";
        xdg.configFile."qt6ct/qt6ct.conf".source = config.dots.src "qt/.config/qt6ct/qt6ct.conf";
        xdg.configFile."gtk-3.0/settings.ini".source = config.dots.src "gtk/.config/gtk-3.0/settings.ini";
        xdg.configFile."gtk-4.0/settings.ini".source = config.dots.src "gtk/.config/gtk-4.0/settings.ini";
        home.file.".local/bin/gsettings-gtk".source = config.dots.src "gtk/.local/bin/gsettings-gtk";
        xdg.configFile."xsettingsd/xsettingsd.conf".source =
          config.dots.src "gtk/.config/xsettingsd/xsettingsd.conf";

        # Mutable kdeglobals (rewritten by KDE apps at runtime).
        xdg.configFile."kdeglobals".source = config.dots.link "kde/.config/kdeglobals";
      };
  };
}
