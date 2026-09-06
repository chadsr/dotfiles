# Networking aspect - NetworkManager with iwd Wi-Fi backend and firewall.
# NOTE: design D2/D15 specifies aggregating ports via a den.quirks.firewall pipe
# emitted by service aspects; the pipe API is wired in defaults.nix. Until the
# quirk plumbing is finalized, service ports are declared here directly.
{ den, ... }:
{
  den.aspects.networking = {
    nixos =
      { lib, ... }:
      {
        networking.networkmanager = {
          enable = true;
          wifi.backend = "iwd";
          # Wi-Fi MAC randomization (translated from 30-randomise-mac.conf).
          # mkForce overrides the NetworkManager module default ("preserve").
          connectionConfig = {
            "connection.cloned-mac-address" = lib.mkForce "stable";
            "wifi.cloned-mac-address" = lib.mkForce "stable";
          };
        };
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ ];
        };
      };

    # networkmanager-dmenu: a dmenu/rofi frontend for NM connections (config only;
    # package installed only if present in nixpkgs).
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        xdg.configFile."networkmanager-dmenu/config.ini".source =
          config.dots.src "networkmanager/.config/networkmanager-dmenu/config.ini";
        home.packages = lib.optional (pkgs ? "networkmanager-dmenu") pkgs.networkmanager-dmenu ++ [
          pkgs.networkmanagerapplet
        ];
      };
  };
}
