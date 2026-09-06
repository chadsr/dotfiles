# Exposes per-host build/switch apps via nh: `nix run .#thinky -- switch`.
{ den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
