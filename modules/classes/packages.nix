# Custom flake-parts class wiring for perSystem packages — registers
# den.classes.packages and routes package modules via den.lib.policy. Custom
# callPackage'd packages would be declared in perSystem.packages here.
{ den, ... }:
{
  den.schema.flake-parts.includes = [ den.policies.packages-to-flake-parts ];

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        waybar-crypto = pkgs.callPackage ../../packages/waybar-crypto.nix { };
      };
    };
}
