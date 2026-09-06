# Common operations wrapper (design D2). Host auto-detected via `hostname -s`,
# username via `whoami`. Run `just` with no args to list recipes.
# Groups: Main (switch/build/boot/update), HM, Dev (fmt/check/ci/dev), Flake
# (write-flake/gc), Test (vm).

host := `hostname -s`
user := `whoami`

# Default: list recipes
default:
    @just --list

# nh os switch (auto-detected host)
switch:
    nix run .#{{host}} -- switch

# switch on next boot
boot:
    sudo nixos-rebuild boot --flake .#{{host}}

# dry-build the current host
build:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel --dry-run

# home-manager switch for the current user@host
hm:
    home-manager switch --flake .#{{user}}@{{host}}

# update flake inputs and commit the lock
update:
    nix --extra-experimental-features 'nix-command flakes' flake update

# format nix files
fmt:
    nix fmt

# nix flake check
check:
    nix --extra-experimental-features 'nix-command flakes' flake check --no-build

# regenerate flake.nix from flake-file.inputs declarations
write-flake:
    nix run .#write-flake

# garbage-collect old generations
gc:
    nix-collect-garbage --delete-older-than 14d

# boot a QEMU VM of the current host config
vm:
    nix run .#vm

# nix develop
dev:
    nix develop
