# Enables `nix run .#vm` — boots the current host's config in QEMU for
# full-system testing instead of rebooting. Uses den's vm-autologin battery.
# The host is auto-detected via the running hostname.
{ inputs, den, ... }:
{
  den.aspects.thinky.includes = [ (den.batteries.vm-autologin "marvin") ];

  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            # Auto-detect the current host from the hostname.
            hosts = builtins.attrNames inputs.self.nixosConfigurations;
          in
          ''
            host="''${1:-$(hostname -s)}"
            # Fall back to the first available host if not found.
            ${builtins.concatStringsSep "\n" (
              map (h: ''
                if [ "$host" = "${h}" ]; then
                  exec ${inputs.self.nixosConfigurations.${h}.config.system.build.vm}/bin/run-${h}-vm "''${@:2}"
                fi
              '') hosts
            )}
            echo "vm: host '$host' not found. Available: ${builtins.concatStringsSep " " hosts}"
            echo "Usage: nix run .#vm [hostname]"
            exit 1
          '';
      };
    };
}
