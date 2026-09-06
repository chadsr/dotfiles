# Browser aspect — librewolf (with overrides + extension policies) +
# ungoogled-chromium (with extension policies). Extensions are defined ONCE in a
# shared list (with both Firefox/AMO and Chromium/Chrome-Web-Store identifiers)
# and policies for both browsers are generated from it.
{ den, ... }:
let
  # Shared browser extension list. Each entry maps to both stores.
  # To add an extension:
  #   1. Find the AMO short ID: addons.mozilla.org/en-US/firefox/addon/<shortId>/
  #   2. Get the Firefox UUID: curl -s "https://addons.mozilla.org/api/v5/addons/addon/<shortId>/" | jq .guid
  #   3. Find the Chrome Web Store ID: chromewebstore.google.com/detail/.../<32-char-id>
  sharedExtensions = [
    {
      shortId = "bitwarden-password-manager";
      uuid = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      chromium = "nngceckbapebfimnlniiiahkandclblb";
    }
    {
      shortId = "floccus";
      uuid = "floccus@handmadeideas.org";
      chromium = "fncnpcdonplblieminflaheggjboofpc";
    }
    {
      shortId = "consent-o-matic";
      uuid = "gdpr@cavi.au.dk";
      chromium = "mdjildafknihffpkfcjnoifjhnimmibg";
    }
    {
      shortId = "ublock-origin";
      uuid = "uBlock0@raymondhill.net";
      chromium = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    }
    {
      shortId = "libredirect";
      uuid = "7esoorv3@alefvanoon.anonaddy.me";
      chromium = "lechemicalgujmdgaiijkgfckphemhlbdp";
    }
    {
      shortId = "clearurls";
      uuid = "{74145f27-f039-47ce-a470-a662b129930a}";
      chromium = "lckanjgmfjdckgmdikgdjfbkmdpjhmhk";
    }
    {
      shortId = "darkreader";
      uuid = "addon@darkreader.org";
      chromium = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    }
  ];

  # Firefox/LibreWolf ExtensionSettings from the shared list.
  firefoxExtensionSettings = builtins.listToAttrs (
    map (e: {
      name = e.uuid;
      value = {
        install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${e.shortId}/latest.xpi";
        installation_mode = "normal_installed";
      };
    }) sharedExtensions
  );

  # Chromium ExtensionInstallForcelist from the shared list.
  chromiumExtensionIds = map (
    e: "${e.chromium};https://clients2.google.com/service/update2/crx"
  ) sharedExtensions;
in
{
  den.aspects.browser = {
    includes = [
      (den.batteries.insecure [
        "librewolf-151.0.2-1"
        "librewolf-unwrapped-151.0.2-1"
      ])
    ];
    nixos =
      { pkgs, ... }:
      {
        # Chromium extension policies (force-installed from the Web Store).
        environment.etc."chromium/policies/managed/extensions.json".source =
          pkgs.writeText "chromium-extensions"
            (builtins.toJSON { ExtensionInstallForcelist = chromiumExtensionIds; });
        # Brave extension policies (same extensions; Brave reads from /etc/brave/).
        environment.etc."brave/policies/managed/extensions.json".source =
          pkgs.writeText "brave-extensions"
            (builtins.toJSON { ExtensionInstallForcelist = chromiumExtensionIds; });
      };
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [
          pkgs.ungoogled-chromium
          pkgs.tor-browser
          pkgs.brave
          # LibreWolf with extension policies (same wrapper as Firefox).
          (pkgs.librewolf.override {
            extraPolicies = {
              ExtensionSettings = firefoxExtensionSettings;
            };
          })
        ];

        # Librewolf overrides (store-managed authored config).
        xdg.configFile."librewolf/librewolf/librewolf.overrides.cfg".source =
          config.dots.src "librewolf/.config/librewolf/librewolf/librewolf.overrides.cfg";

        programs.chromium = {
          enable = true;
          package = pkgs.ungoogled-chromium;
          commandLineArgs = [
            "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
            "--ozone-platform=wayland"
            "--force-dark-mode"
          ];
        };
      };
  };
}
