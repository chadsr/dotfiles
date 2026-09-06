# Darwin aspect - system.defaults (translated from setup-macos.sh defaults write),
# LaunchAgents (gpg-agent), KeyBindings, cask-only homebrew. darwin stateful init
# is scoped to GPG provisioning + these defaults (design D8/9.6).
{ den, ... }:
{
  den.aspects.macos = {
    darwin = {
      # Translated from setup-macos.sh:261-274 (defaults write ...).
      system.defaults = {
        dock = {
          autohide = true;
          orientation = "bottom";
        };
        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          FXPreferredViewStyle = "clmv";
        };
        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 14;
          KeyRepeat = 1;
          "com.apple.keyboard.fnState" = true;
          AppleICUForce24HourTime = true;
        };
      };

      # Homebrew: cask-only and minimal (design D7/9.2).
      homebrew = {
        enable = true;
        brews = [ ];
        casks = [
          "stats"
          "theseal/ssh-askpass/ssh-askpass"
        ];
      };

      # GPG agent LaunchAgent replaces imperative launchctl load (9.4).
      launchd.agents.gpg-agent = {
        enable = true;
        config = {
          Label = "org.gnupg.gpg-agent";
          RunAtLoad = true;
          KeepAlive = true;
          Program = "/opt/homebrew/bin/gpg-agent";
          ProgramArguments = [
            "gpg-agent"
            "--daemon"
          ];
        };
      };
    };

    # DefaultKeyBinding.dict -> ~/Library/KeyBindings/ (9.5).
    provides.to-users.homeManager =
      { config, ... }:
      {
        home.file."Library/KeyBindings/DefaultKeyBinding.dict".source =
          config.dots.src "macos/Library/KeyBindings/DefaultKeyBinding.dict";
      };
  };
}
