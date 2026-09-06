# Dev-tools aspect — the Android mobile-dev stack (android-tools + android-studio,
# marvin in the adbusers group). AI/dev-assistant tooling lives in the `ai`
# aspect; figma in the `design` aspect. Radicle keys are deployed via the sops
# secrets store (secrets/manifest.nix).
{ den, ... }:
{
  den.aspects.dev-tools = {
    # android-studio — unfree (Google proprietary license)
    includes = [ (den.batteries.unfree [ "android-studio" ]) ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          android-tools
          android-studio
        ];
      };

    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # Android Studio options/*.xml — derive the config-dir suffix from the
        # package version (first three dotted components, e.g. "2025.3.1").
        # The 9 tracked XMLs are linked into the version-derived options dir.
        home.file.".config/Google/AndroidStudio${lib.concatStringsSep "." (lib.take 3 (lib.splitVersion pkgs.android-studio.version))}/options".source =
          config.dots.src "android/.config/Google/AndroidStudio2025.3.1/options";

        # Radicle config + public key (private key is a sops secret).
        home.file.".radicle/config.json".source = config.dots.src "radicle/.radicle/config.json";
        home.file.".radicle/keys/radicle.pub".source = config.dots.src "radicle/.radicle/keys/radicle.pub";
      };
  };
}
