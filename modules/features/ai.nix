# AI aspect — OpenSpec + the AI/dev-assistant tooling: opencode, cline, goose,
# continue, crush, forge, mcp, docker-mcp, skillshare, and the ollama service.
# Installs openspec, deploys authored configs, binds mutable state two-way into
# the repo, and runs the openspec-workspace -> skillshare activation order
# (design D8 / task 6.5).
{ den, ... }:
{
  den.aspects.ai = {
    # ollama service with declarative model pulls (moved from system-services).
    nixos =
      { lib, ... }:
      {
        services.ollama = {
          enable = lib.mkDefault true;
          loadModels = lib.mkDefault [ ];
        };
      };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = with pkgs; [
          openspec
          goose
        ];

        # Authored assistant configs (store-managed).
        xdg.configFile."opencode/opencode.jsonc".source =
          config.dots.src "opencode/.config/opencode/opencode.jsonc";
        xdg.configFile."cline/data/settings/cline_mcp_settings.json".source =
          config.dots.src "cline/.cline/data/settings/cline_mcp_settings.json";
        xdg.configFile."openspec/config.json".source =
          config.dots.src "openspec/.config/openspec/config.json";

        # Mutable assistant state (two-way into the repo).
        xdg.configFile."opencode/tui.json".source = config.dots.link "opencode/.config/opencode/tui.json";
        xdg.configFile."cline/data/settings/global-settings.json".source =
          config.dots.link "cline/.cline/data/settings/global-settings.json";
        xdg.configFile."goose/config.yaml".source = config.dots.link "goose/.config/goose/config.yaml";
        xdg.configFile."goose/permission.yaml".source =
          config.dots.link "goose/.config/goose/permission.yaml";
        xdg.configFile."crush/crush.json".source = config.dots.link "crush/.config/crush/crush.json";
        xdg.configFile."forge/.forge.toml".source = config.dots.link "forge/.config/forge/.forge.toml";
        xdg.configFile."forge/.mcp.json".source = config.dots.link "forge/.config/forge/.mcp.json";
        home.file.".mcp.json".source = config.dots.link "mcp/.mcp.json";
        home.file.".continue/config.yaml".source = config.dots.link "continue/.continue/config.yaml";
        # docker-mcp: MCP profiles/servers (rewritten by docker mcp).
        xdg.configFile."docker/mcp/profiles/dev-tools.yaml".source =
          config.dots.link "docker/.docker/mcp/profiles/dev-tools.yaml";
        xdg.configFile."docker/mcp/servers/debugmcp.yaml".source =
          config.dots.link "docker/.docker/mcp/servers/debugmcp.yaml";
        # skillshare: only metadata tracked (two-way); bodies activation-populated.
        xdg.configFile."skillshare/skills/.metadata.json".source =
          config.dots.link "skillshare/.config/skillshare/skills/.metadata.json";

        # OpenSpec "shared" workspace, two-way bound into the repo.
        xdg.dataFile."openspec/workspaces/shared".source =
          config.dots.link "openspec/.local/share/openspec/workspaces/shared";

        # Stateful init (task 6.5): refresh the workspace FIRST, then sync skills.
        home.activation.openspec-workspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if command -v openspec >/dev/null 2>&1; then
            openspec workspace update --workspace shared || true
          fi
        '';
        home.activation.skillshare-sync =
          lib.hm.dag.entryAfter
            [
              "writeBoundary"
              "openspec-workspace"
            ]
            ''
              if command -v skillshare >/dev/null 2>&1; then
                skillshare install || true
                skillshare sync --all || true
              fi
            '';
      };
  };
}
