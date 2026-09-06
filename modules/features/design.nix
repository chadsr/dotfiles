# Design aspect — design tools. Currently figma-linux (GUI design tool) and its
# mutable settings. figma-linux rewrites settings.json at runtime (clientId /
# userId identifiers; verify it holds no OAuth tokens — design D11 caveat).
{ den, ... }:
{
  den.aspects.design = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [ pkgs.figma-linux ];
        # figma-linux settings.json is program-rewritten at runtime → two-way.
        xdg.configFile."figma-linux/settings.json".source =
          config.dots.link "figma/.config/figma-linux/settings.json";
      };
  };
}
