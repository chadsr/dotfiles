# Global defaults applied to ALL hosts/users/homes via den.default.*, plus the
# global battery includes and the registered quirks. stateVersion is pinned at
# first install and never changed.
{ lib, den, ... }:
{
  den.default.homeManager =
    { config, lib, ... }:
    {
      # On-disk path to the dotfiles repo. Populated per-host from the freeform
      # host attribute (see the parametric include below) so aspects can build
      # mkOutOfStoreSymlink targets into the live checkout.
      options.dotfilesRepo = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "On-disk path to the dotfiles repo (for mkOutOfStoreSymlink targets).";
      };

      # dotsLink helper (vic-style): `config.dots.link "btop/.config/btop/btop.conf"`
      # expands to an mkOutOfStoreSymlink into modules/dots/<path> under the repo.
      # Defined once here; every aspect's homeManager block can use it directly.
      options.dots.link = lib.mkOption {
        type = lib.types.functionTo lib.types.raw;
        default = path: config.lib.file.mkOutOfStoreSymlink "${config.dotfilesRepo}/modules/dots/${path}";
        description = "mkOutOfStoreSymlink into modules/dots/, relative to config.dotfilesRepo. Usage: config.dots.link \"<path-under-modules/dots>\".";
      };

      # dotsSrc helper: `config.dots.src "nvim/.config/nvim"` → a store-managed
      # path into modules/dots/ (read-only, copied into the Nix store). Change the
      # default here if the dots directory ever moves — all call sites update.
      options.dots.src = lib.mkOption {
        type = lib.types.functionTo lib.types.path;
        default = sub: ./dots + "/${sub}";
        description = "Store-managed dotfile source: config.dots.src \"nvim/.config/nvim\" → modules/dots/nvim/.config/nvim.";
      };

      config.home.stateVersion = "26.05";
      # Unfree packages are opted-in per-aspect via den.batteries.unfree (not a
      # blanket allowUnfree) so the unfree set stays explicit and auditable.
    };

  # nix-darwin stateVersion is an integer (the darwin schema version).
  den.default.darwin.system.stateVersion = 7;

  # Enable Home Manager for every user by default.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.default.nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      system.stateVersion = "26.05";

      # HM shares the OS pkgs (one instance). The den batteries skip their
      # nixpkgs.config setting when globalPkgs=true (their !globalPkgs guard);
      # this bridge reads the collected lists and sets the config directly,
      # covering BOTH OS and HM packages so per-aspect unfree/insecure opt-ins
      # work from home.packages (no environment.systemPackages workaround).
      home-manager.useGlobalPkgs = true;
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.unfree.packages;
      nixpkgs.config.permittedInsecurePackages = config.permittedInsecurePackages.packages;

      i18n.defaultLocale = "en_GB.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "nl_NL.UTF-8";
        LC_IDENTIFICATION = "nl_NL.UTF-8";
        LC_MEASUREMENT = "nl_NL.UTF-8";
        LC_MONETARY = "nl_NL.UTF-8";
        LC_NAME = "nl_NL.UTF-8";
        LC_NUMERIC = "nl_NL.UTF-8";
        LC_PAPER = "nl_NL.UTF-8";
        LC_TELEPHONE = "nl_NL.UTF-8";
        LC_TIME = "nl_NL.UTF-8";
      };
      time.timeZone = "Europe/Amsterdam";

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # NTP time sync (chrony: better post-suspend re-sync than timesyncd).
      services.chrony.enable = true;

      # Store maintenance + marvin as a trusted user.
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      nix.optimise.automatic = true;
      nix.settings.trusted-users = [
        "root"
        "marvin"
      ];

      console.keyMap = "us-acentos";
      services.xserver.xkb = {
        layout = "us";
        variant = "altgr-intl";
      };
    };

  # Batteries applied globally to every entity.
  den.default.includes = [
    den.batteries.define-user
    den.batteries.hostname
    den.batteries.inputs'
    den.batteries.self'
    # Deliver each host's freeform `dotfilesRepo` attribute to its users' HM
    # config, so aspects can reference `config.dotfilesRepo` for mkOutOfStoreSymlink.
    (
      { host, ... }:
      {
        provides.to-users.homeManager.dotfilesRepo = host.dotfilesRepo or "";
      }
    )
  ];

  # Registered quirk: service aspects emit `firewall = { ports = [...]; }` and the
  # networking aspect consumes the aggregated port list.
  den.quirks.firewall.description = "Aggregated firewall port declarations collected from service aspects.";
}
