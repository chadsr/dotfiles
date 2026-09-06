# Privacy aspect — privacy-preserving tools. Currently VeraCrypt (disk/file
# encryption; unfree under the TrueCrypt-derived VeraCrypt License). Wi-Fi MAC
# randomization lives in the networking aspect (it is NetworkManager config).
{ den, ... }:
{
  den.aspects.privacy = {
    # veracrypt — unfree (TrueCrypt-derived VeraCrypt License)
    includes = [ (den.batteries.unfree [ "veracrypt" ]) ];
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          veracrypt
          amnezia-vpn
        ];
      };
  };
}
