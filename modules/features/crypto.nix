# Crypto aspect — crypto hardware wallet tooling. Currently the Ledger wallet:
# ledger-live-desktop (GUI) + ledger-udev-rules (hardware device permissions).
{ den, ... }:
{
  den.aspects.crypto = {
    nixos =
      { pkgs, ... }:
      {
        # Ledger hardware wallet udev rules so the device is accessible.
        services.udev.packages = [ pkgs.ledger-udev-rules ];
      };
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ledger-live-desktop ];
      };
  };
}
