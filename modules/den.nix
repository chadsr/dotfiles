# Den + flake-file wiring. Imports the dendritic flake-parts modules from both
# flake-file (auto-generates flake.nix) and den (feature/aspect framework), then
# declares every flake input near its usage via flake-file.inputs. Run
# `nix run .#write-flake` to regenerate flake.nix from these declarations.
{ inputs, lib, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
    (inputs.den.flakeModules.denTest or { })
  ];

  flake-file.inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.follows = "nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };

    den.url = "github:denful/den";
    import-tree.url = "github:vic/import-tree";
    flake-file.url = "github:vic/flake-file";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Named `darwin` because den references inputs.darwin.lib.darwinSystem.
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    # VS Code/Codium extensions from the Marketplace + Open VSX (~80k, daily).
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # Chaotic Nyx supplies the CachyOS kernel + CachyOS/GE Proton for shifty.
    # It MUST NOT set inputs.nixpkgs.follows - doing so breaks its binary cache.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };
}
