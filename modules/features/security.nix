# Security aspect - sshd hardening and sudo (nixos).
{ den, ... }:
{
  den.aspects.security = {
    nixos =
      { lib, ... }:
      {
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
        security.sudo.enable = lib.mkDefault true;
      };
  };
}
