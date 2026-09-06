# Battery aspect — laptop power management + battery notifications. Currently:
# TLP (charge limit + aggressive power saving) on the nixos side, and batsignal
# (battery level notifications) on the HM side. Thinky-only (included by the
# thinky host aspect, not the shared desktop composite).
{ den, ... }:
{
  den.aspects.battery = {
    nixos =
      { ... }:
      {
        services.tlp = {
          enable = true;
          settings = {
            STOP_CHARGE_THRESH_BAT0 = 80;
            PCIE_ASPM_ON_BAT = "powersupersave";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            INTEL_GPU_MIN_FREQ_ON_BAT = 0;
            INTEL_GPU_MAX_FREQ_ON_BAT = 800;
            INTEL_GPU_BOOST_FREQ_ON_BAT = 800;
          };
        };
      };

    provides.to-users.homeManager =
      { ... }:
      {
        # Battery level notifications (warning at 90/80/70%, critical at 15%).
        services.batsignal.enable = true;
      };
  };
}
