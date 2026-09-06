# Secrets aspect — wires sops-nix (GPG backend) into NixOS and Darwin. Declares
# every secret from secrets/manifest.nix, plus the Yubikey-held GPG key as the
# decryption identity. The actual secret VALUES live in secrets/secrets.yaml
# (sops-encrypted to the GPG subkey 0x79C70BBE4865D828); populate placeholders
# via `sops secrets/secrets.yaml` (decrypts with the Yubikey).
{ inputs, ... }:
let
  manifest = import ../../secrets/manifest.nix;
  # Generate sops.secrets declarations from the manifest data.
  secretsFromManifest = builtins.mapAttrs (_: v: v) manifest;
in
{
  den.aspects.secrets = {
    nixos =
      { lib, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops.defaultSopsFile = ../../secrets/secrets.yaml;
        sops.gnupg.home = "/var/lib/sops-nix";
        # GPG backend only (no age, no ssh-host-key derivation): the openssh
        # module auto-sets gnupg.sshKeyPaths which would conflict with gnupg.home
        # (sops asserts exactly one); force it empty to keep the Yubikey path.
        sops.gnupg.sshKeyPaths = lib.mkForce [ ];
        sops.secrets = secretsFromManifest;
      };
    darwin =
      { lib, ... }:
      {
        imports = [ inputs.sops-nix.darwinModules.sops ];
        sops.defaultSopsFile = ../../secrets/secrets.yaml;
        sops.gnupg.home = "/var/lib/sops-nix";
        sops.gnupg.sshKeyPaths = lib.mkForce [ ];
        # On darwin only the cross-platform secrets decrypt (ssh config, etc.);
        # the Linux-only app configs are still declared but inert here.
        sops.secrets = {
          "marvin-hashed-password" = { };
        };
      };
  };
}
