# Containers aspect - docker (+ buildx, compose, credential-helpers),
# libvirtd, virtualbox (nixos). Docker config.json is mutable (two-way) — it
# stores credsStore helper + MCP profile references, rewritten by docker login
# and docker mcp commands.
{ den, ... }:
{
  den.aspects.containers = {
    nixos =
      { pkgs, ... }:
      {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
        };
        environment.systemPackages = with pkgs; [
          docker-compose
          docker-buildx
          docker-credential-helpers
          qemu
        ];

        virtualisation.libvirtd.enable = true;
      };

    provides.to-users.homeManager =
      { config, ... }:
      {
        # Docker config.json (mutable).
        xdg.configFile."docker/config.json".source = config.dots.link "docker/.docker/config.json";
      };
  };
}
