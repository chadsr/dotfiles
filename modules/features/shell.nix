# Shell aspect — zsh + bash rc files, linked two-way into the repo so they stay
# editable and lintable (shellcheck/shfmt) as real files rather than inline Nix
# strings. The repo .zshrc/.bashrc source the plugins (portable: Arch + Nix
# profile paths), starship, aliases, and tool init. HM only installs the shells,
# the plugin packages, and the broad session env (from the former environment.d).
{ den, ... }:
{
  den.aspects.shell = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        # Shell rc files — two-way bind into the repo
        home.file = {
          ".zshrc".source = config.dots.link "zsh/.zshrc";
          ".zshenv".source = config.dots.link "zsh/.zshenv";
          ".zprofile".source = config.dots.link "zsh/.zprofile";
          ".zlogin".source = config.dots.link "zsh/.zlogin";
          ".zlogout".source = config.dots.link "zsh/.zlogout";
          ".bashrc".source = config.dots.link "bash/.bashrc";
          ".bash_profile".source = config.dots.link "bash/.bash_profile";
          ".bash_login".source = config.dots.link "bash/.bash_login";
          ".bash_logout".source = config.dots.link "bash/.bash_logout";
          ".bash_env".source = config.dots.link "bash/.bash_env";
          ".aliases".source = config.dots.link "zsh/.aliases";
        };

        # Shells + plugins + prompt. The rc files eval starship init themselves.
        home.packages = with pkgs; [
          zsh-autosuggestions
          zsh-syntax-highlighting
          zsh-autocomplete
          starship
        ];
        xdg.configFile."starship.toml".source = config.dots.src "starship/.config/starship.toml";

        # Session environment consolidated from the former environment.d files
        # (BEMENU_BACKEND dropped per spec). Shell-session-specific vars (PATH,
        # HISTFILE, GPG_TTY, GOPATH, ANDROID, CARGO, EDITOR) live in the linked
        # .zshenv/.bash_env above, so they are lintable too.
        home.sessionVariables = {
          DOTFILES = config.dotfilesRepo;
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "wayland";
          ELECTRON_TRASH = "gio";
          XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
          _JAVA_AWT_WM_NONREPARENTING = "1";
          QT_WAYLAND_FORCE_DPI = "physical";
        };
        home.sessionPath = [
          "$HOME/.local/bin"
          config.dotfilesRepo
        ];
      };
  };
}
