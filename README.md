# dotfiles

[![CI](https://github.com/chadsr/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/chadsr/dotfiles/actions/workflows/ci.yml)

My systems, declared as a single Nix flake using the **[den](https://den.denful.dev)**
feature/aspect model on top of **flake-parts**. Three hosts share one user
environment:

- **thinky** - NixOS laptop (x86_64-linux)
- **shifty** - NixOS desktop (x86_64-linux)
- **macy** - nix-darwin (aarch64-darwin)

The flake exposes `nixosConfigurations.thinky`, `nixosConfigurations.shifty`, and
`darwinConfigurations.macy`, all composed from **den aspects** (features as
functions of context) under `modules/`.

## Prerequisites

- Nix with flakes (`experimental-features = nix-command flakes`)
- A Yubikey holding the GPG key `0x2B7340DB13C85766` (subkey
  `0x79C70BBE4865D828`) - used for git signing, SSH auth, **and** sops secrets.
  No `age` identity is used.
- [direnv](https://direnv.net) + nix-direnv (optional, for auto-loading the dev
  shell on `cd`)

## Repository setup

```shell
git clone git@github.com:chadsr/dotfiles.git && cd dotfiles/
nix run .#write-flake   # regenerate flake.nix from flake-file.inputs
nix --extra-experimental-features 'nix-command flakes' flake lock
```

`flake.nix` is **auto-generated** by [flake-file](https://github.com/vic/flake-file)

- never hand-edit it. Inputs are declared near usage in `modules/den.nix` via
  `flake-file.inputs.*`; re-run `nix run .#write-flake` after changing them.

## Structure

```
modules/                 # import-tree root - every .nix auto-imported
  den.nix                # flake-file + den wiring, all flake inputs
  hosts.nix              # den.hosts declarations + freeform attrs (disk/ramMiB/dotfilesRepo)
  defaults.nix           # den.default.* (locale, timezone, stateVersion, batteries)
  hosts/                 # per-host aspect enhancements (thinky, shifty, macy)
  users/                 # per-user aspect enhancements (marvin)
  features/              # cross-cutting feature aspects (audio, gpg, shell, editors, ...)
  classes/               # custom flake-parts perSystem classes (packages)
  tests/                 # nix-unit denTest behavioral tests
  nh.nix / vm.nix        # nh build apps + QEMU VM runner
secrets/                 # sops store (secrets.yaml) + manifest.nix
packages/                # custom derivations (none currently — hackneyed uses the nixpkgs override)
overlays/                # nixpkgs overlays
```

Each aspect is a function of context (`{ host, user }: { nixos = ...; homeManager = ...; }`).
HM config lives inside each feature aspect (no separate `home/` tree). Mutable
configs use `mkOutOfStoreSymlink` into `${config.dotfilesRepo}` for two-way git
parity; read-only authored configs use `source`.

## Provisioning a new NixOS host

1. Set freeform attrs in `modules/hosts.nix` (`disk`, `ramMiB`, `dotfilesRepo`).

1. `nix run .#write-flake`

1. disko format:

   ```shell
   nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#<host>
   ```

1. `nixos-install --flake .#<host>` - on first boot sops decrypts via the
   Yubikey GPG key.

## Provisioning a new darwin host

```shell
nix run .#write-flake
darwin-rebuild switch --flake .#macy
```

## Day-to-day operations

`just` wraps the common operations (host/username auto-detected):

| Command | Effect |
| ------------------ | --------------------------------------- |
| `just switch` | nh os switch (current host) |
| `just boot` | switch on next boot |
| `just build` | dry-build current host |
| `just hm` | home-manager switch (current user@host) |
| `just update` | `nix flake update` |
| `just fmt` | nixfmt |
| `just check` | `nix flake check --no-build` |
| `just vm` | boot QEMU VM of the host config |
| `just write-flake` | regenerate flake.nix |

## Secrets management

Secrets live in `secrets/secrets.yaml` (sops-encrypted to the Yubikey-backed GPG
subkey; **no age**). `secrets/manifest.nix` maps each secret key to its on-disk
target path, owner, group, and mode.

```shell
sops secrets/secrets.yaml        # edit/add secrets
```

The GPG public key is imported and TOFU-trusted at activation; `pcscd` +
`gpg-agent` decrypt via the Yubikey. Keep an offline backup GPG subkey (or a
cloned secondary Yubikey) for recovery. The `~/.password-store` is committed to
the repo (GPG-encrypted) and bound two-way via `mkOutOfStoreSymlink`.

## Adding a new host

1. Create `modules/hosts/<name>.nix` (`den.aspects.<name>.includes = [ den.aspects.desktop-linux ];` + host-specific deltas).
1. Register it in `modules/hosts.nix`: `den.hosts.x86_64-linux.<name>.users.marvin = {};` with freeform attrs.
1. Run the parity checklist (units, packages, dotfile paths, secrets, services).

## Adding a new aspect

1. Create `modules/features/<name>.nix` declaring `den.aspects.<name>`.
1. Add it to the relevant composite (`features/desktop-linux.nix` or `features/macos-base.nix`).
1. Add a `modules/tests/<name>.nix` denTest.

## Unresolved packages

The former Arch pkglist (`data/pkgs/*.txt`) is the source of truth for package
parity. Package resolution (nixpkgs attribute / module / community flake / not
available) is tracked per the `package-mapping.md` work (tasks 5.2–5.4). CachyOS
kernel + CachyOS/GE Proton come from Chaotic Nyx; everything else is nixpkgs.
