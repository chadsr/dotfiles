# CAD/3D-printing aspect — Cura and PrusaSlicer. The config files
# (cura.cfg, PrusaSlicer.ini) are two-way synced (program-rewritten at runtime).
# Both packages were removed from nixpkgs under their original names; cura-appimage
# and prusa-slicer are the current attributes.
{ den, ... }:
{
  den.aspects.cad =
    { pkgs, ... }:
    {
      # cura-appimage — unfree (Ultimaker proprietary binaries in the AppImage)
      includes = [ (den.batteries.unfree [ "cura-appimage" ]) ];
      provides.to-users.homeManager =
        { config, ... }:
        {
          home.packages = with pkgs; [
            cura-appimage
            prusa-slicer
          ];

          # Two-way synced configs (rewritten by the slicer at runtime).
          xdg.configFile."cura/5.11/cura.cfg".source = config.dots.link "cura/.config/cura/5.11/cura.cfg";
          xdg.configFile."PrusaSlicer/PrusaSlicer.ini".source =
            config.dots.link "prusaslicer/.config/PrusaSlicer/PrusaSlicer.ini";
        };
    };
}
