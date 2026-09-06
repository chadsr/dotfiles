# The marvin user aspect. define-user + primary-user batteries create the OS
# account (isNormalUser, wheel/networkmanager); this aspect extends it with the
# full Arch->NixOS group mapping, the sops-backed password, and the login shell.
# The GPG key id is declared once (let-binding fixed-point) and reused by the
# gpg aspect.
{ den, config, ... }:
let
  # Primary GPG key reused for signing, SSH, and sops. Declared once here and
  # referenced wherever the key id is needed.
  gpgKey = "0x2B7340DB13C85766";
in
{
  den.aspects.marvin = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
    ];

    meta.gpgKey = gpgKey;

    nixos = {
      users.users.marvin = {
        # Arch->NixOS group mapping (primary-user already adds wheel + networkmanager).
        extraGroups = [
          "wheel"
          "audio"
          "video"
          "render"
          "input"
          "dialout"
          "i2c"
          "networkmanager"
          "docker"
          "libvirtd"
          "kvm"
          "gamemode"
          "adbusers"
        ];
        # sops-nix default path for the marvin-hashed-password secret. The secret
        # is declared (owner/mode) in features/secrets.nix at host scope.
        hashedPasswordFile = "/run/secrets/marvin-hashed-password";
      };
      security.sudo.enable = true;
    };
  };
}
