# Composite aspect bundling the shared Linux desktop feature set. Each host
# aspect (thinky, shifty) includes this and adds host-specific deltas. The disk
# layout is owned by the disk-layout aspect (disko); systemd-boot is declared
# here.
{ den, inputs, ... }:
{
  den.aspects.desktop-linux = {
    includes = [
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.compositor
      den.aspects.hyprland
      den.aspects.sway
      den.aspects.networking
      den.aspects.security
      den.aspects.containers
      den.aspects.system-services
      den.aspects.gpg
      den.aspects.git
      den.aspects.shell
      den.aspects.editors
      den.aspects.dev-tools
      den.aspects.ai
      den.aspects.languages
      den.aspects.theming
      den.aspects.cli-tools
      den.aspects.design
      den.aspects.crypto
      den.aspects.browser
      den.aspects.file-manager
      den.aspects.media
      den.aspects.productivity
      den.aspects.cad
      den.aspects.gaming
      den.aspects.privacy
      den.aspects.secrets
      den.aspects.disk-layout
      den.aspects.desktop
    ];

    nixos = {
      # disko (disk layout); Chaotic Nyx is imported only by shifty (CachyOS
      # kernel/proton), not the shared composite.
      imports = [ inputs.disko.nixosModules.disko ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
