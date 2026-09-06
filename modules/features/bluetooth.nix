# Bluetooth aspect — hardware.bluetooth + per-host main.conf (translated from the
# former system/{thinky,shifty}/etc/bluetooth/main.conf). AutoEnable resumes the
# controller after suspend; the reconnect policy matches the old Policy section.
{ den, ... }:
{
  den.aspects.bluetooth = {
    nixos =
      { ... }:
      {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              AlwaysPairable = false;
              PairableTimeout = 420;
              Experimental = true;
              ControllerMode = "dual";
            };
            Policy = {
              ReconnectAttempts = 7;
              ReconnectIntervals = "1,2,4,8,16,32,64";
              AutoEnable = true;
              ResumeDelay = 10;
            };
          };
        };
      };
  };
}
