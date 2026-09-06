# Disk layout aspect — declarative disk provisioning via disko (design D13).
# GPT disk: unencrypted ESP (/boot, FAT32) + 4 separate LUKS volumes (root, nix,
# home, swap), each data FS as LUKS + btrfs (+ subvolumes) on root/nix/home.
# Root unlocks via Yubikey FIDO2 (primary) or typed passphrase (fallback); a
# random keyfile (initrd-resident via boot.initrd.secrets, decrypted from sops)
# auto-unlocks /nix, /home, swap. swap = host RAM (hibernation). snapper rolls
# back the root subvolume. Reads the freeform host attrs `host.disk`/`host.ramMiB`.
{ den, ... }:
{
  den.aspects.disk-layout =
    { host, ... }:
    let
      disk = host.disk or "/dev/sda";
      ramMiB = host.ramMiB or 16384;
      # Initrd-resident keyfile path (baked in via boot.initrd.secrets).
      keyfile = "/crypto_keyfile.bin";
      btrfsOpts = [
        "compress=zstd"
        "noatime"
        "ssd"
      ];
    in
    {
      nixos =
        { config, lib, ... }:
        let
          keyfileSecret = config.sops.secrets."luks-secondary-keyfile".path;
          # The keyfile only exists at runtime (sops-decrypted) on the running
          # system. boot.initrd.secrets copies a build-time path into the initrd,
          # so this is conditional: skipped during CI/flake-check (file absent)
          # and applied when rebuilding on the running host post-install.
          keyfileReady = builtins.pathExists keyfileSecret;
        in
        {
          # systemd initrd is required for FIDO2 unlock (systemd-cryptenroll).
          boot.initrd.systemd.enable = true;

          # Bake the sops-decrypted secondary keyfile into the initrd so /nix,
          # /home, and swap auto-unlock before root (hibernation resume). This
          # rebuild must run on the already-running system (where sops works) as
          # a one-time post-install bootstrap step.
          boot.initrd.secrets = lib.mkIf keyfileReady { ${keyfile} = /. + keyfileSecret; };

          # snapper: scheduled snapshots + rollback on the root subvolume.
          services.snapper.configs.root = {
            SUBVOLUME = "/";
            ALLOW_GROUPS = [ "wheel" ];
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
            TIMELINE_LIMIT_HOURLY = 12;
            TIMELINE_LIMIT_DAILY = 7;
            TIMELINE_LIMIT_WEEKLY = 0;
            TIMELINE_LIMIT_MONTHLY = 0;
            TIMELINE_LIMIT_YEARLY = 0;
          };
          services.snapper.snapshotInterval = "hourly";

          disko.devices = {
            disk.main = {
              device = disk;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    size = "1G";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  # Root: FIDO2 (primary) + passphrase (fallback). FIDO2
                  # credentials are enrolled at install via systemd-cryptenroll;
                  # the passphrase is the sops-stored recovery secret.
                  luks-root = {
                    size = "60G";
                    content = {
                      type = "luks";
                      name = "crypted-root";
                      settings = {
                        allowDiscards = true;
                        crypttabExtraOpts = [ "fido2-device=auto" ];
                      };
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ];
                        subvolumes = {
                          "@root" = { };
                          "@root/@" = {
                            mountpoint = "/";
                            mountOptions = btrfsOpts;
                          };
                          "@root/@snapshots" = {
                            mountpoint = "/.snapshots";
                            mountOptions = btrfsOpts;
                          };
                        };
                      };
                    };
                  };
                  # /nix: auto-unlocks via the initrd keyfile.
                  luks-nix = {
                    size = "40G";
                    content = {
                      type = "luks";
                      name = "crypted-nix";
                      settings = {
                        allowDiscards = true;
                        keyFile = keyfile;
                      };
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ];
                        subvolumes = {
                          "@nix" = {
                            mountpoint = "/nix";
                            mountOptions = btrfsOpts;
                          };
                        };
                      };
                    };
                  };
                  # /home: auto-unlocks via the initrd keyfile.
                  luks-home = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "crypted-home";
                      settings = {
                        allowDiscards = true;
                        keyFile = keyfile;
                      };
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ];
                        subvolumes = {
                          "@home" = {
                            mountpoint = "/home";
                            mountOptions = btrfsOpts;
                          };
                        };
                      };
                    };
                  };
                  # swap: sized to host RAM for hibernation; auto-unlocks via keyfile.
                  swap = {
                    size = builtins.toString ramMiB;
                    content = {
                      type = "luks";
                      name = "crypted-swap";
                      settings = {
                        allowDiscards = true;
                        keyFile = keyfile;
                      };
                      content.type = "swap";
                      content.randomEncryption = false;
                    };
                  };
                };
              };
            };
          };
        };
    };
}
