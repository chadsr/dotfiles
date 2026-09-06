# macy host aspect (macOS -> nix-darwin). Includes the darwin base composite.
{ den, ... }:
{
  den.aspects.macy = {
    includes = [ den.aspects.macos-base ];
  };
}
