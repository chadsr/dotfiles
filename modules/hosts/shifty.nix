# shifty host aspect (Arch desktop -> NixOS). Includes the shared Linux desktop
# composite (gaming, audio, compositor, ...) plus the shifty-only tuning aspect
# (CoolerControl/LACT/liquidctl daemons). Everything host-specific to shifty's
# hardware lives here: the CachyOS kernel, the amdgpu ppfeaturemask, the Dell
# S3422DWG ICC profile, and power-profiles-daemon (shifty's power manager, vs
# thinky's TLP).
{ den, inputs, ... }:
{
  den.aspects.shifty = {
    includes = [
      den.aspects.desktop-linux
      den.aspects.tuning
    ];

    nixos =
      { pkgs, ... }:
      {
        # Chaotic Nyx supplies the CachyOS kernel (+ CachyOS/GE Proton); imported
        # only on shifty, not the shared composite.
        imports = [ inputs.chaotic.nixosModules.default ];

        # CachyOS kernel from Chaotic Nyx (EEVDF-BORE scheduler, sched-ext).
        boot.kernelPackages = pkgs.linuxPackages_cachyos;
        # amdgpu ppfeaturemask (measured once, deterministic - design D9).
        # TODO(4.4): replace with the value measured on shifty.
        boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

        # shifty's power manager (mutually exclusive with thinky's TLP).
        services.power-profiles-daemon.enable = true;

        # Dell S3422DWG ICC colour profile via colord (shifty's monitor).
        services.colord.enable = true;
        environment.systemPackages = [
          (pkgs.runCommand "s3422dwg-icc" { } ''
            mkdir -p $out/share/color/icc
            cp ${../../system/shifty/usr/share/color/icc/colord/S3422DWG.icc} $out/share/color/icc/S3422DWG.icc
          '')
        ];
      };
  };
}
