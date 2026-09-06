# Editors aspect - neovim, helix, zed, vscodium. VSCodium is wrapped with its
# extensions via nix-vscode-extensions (declarative extension management). Mutable
# editor state (vscodium settings/keybindings/argv, zed settings.json) is two-way
# bound via mkOutOfStoreSymlink per design D11.
{ den, inputs, ... }:
let
  # Extension list (from `codium --list-extensions`).
  extensions = m: [
    m.bradlc."vscode-tailwindcss"
    m.catppuccin."catppuccin-vsc"
    m.catppuccin."catppuccin-vsc-icons"
    m.charliermarsh.ruff
    m.continue.continue
    m.coolbear."systemd-unit-file"
    m.davidanson."vscode-markdownlint"
    m.dbaeumer."vscode-eslint"
    m.detachhead.basedpyright
    m.docker.docker
    m.eamodio.gitlens
    m.editorconfig.editorconfig
    m.esbenp."prettier-vscode"
    m.esphome."esphome-vscode"
    m."ewen-lbh"."vscode-hyprls"
    m.fireblast."hyprlang-vscode"
    m.firsttris."vscode-jest-runner"
    m.github."vscode-github-actions"
    m.github."vscode-pull-request-github"
    m.golang.go
    m.graphql."vscode-graphql"
    m.graphql."vscode-graphql-syntax"
    m.inlang."vs-code-extension"
    m."james-yu"."latex-workshop"
    m.jnoortheen."nix-ide"
    m.johnnymorganz.stylua
    m."mads-hartmann"."bash-ide-vscode"
    m.mathematic."vscode-latex"
    m.mechatroner."rainbow-csv"
    m.michaelneale."goose-vscode"
    m."ms-azuretools"."vscode-containers"
    m."ms-azuretools"."vscode-docker"
    m."ms-playwright".playwright
    m."ms-python".debugpy
    m."ms-python".isort
    m."ms-python".python
    m."ms-python"."vscode-pylance"
    m."ms-python"."vscode-python-envs"
    m."ms-toolsai".datawrangler
    m."ms-toolsai".jupyter
    m."ms-toolsai"."jupyter-keymap"
    m."ms-toolsai"."jupyter-renderers"
    m."ms-toolsai"."vscode-jupyter-cell-tags"
    m."ms-toolsai"."vscode-jupyter-slideshow"
    m."ms-vscode-remote"."remote-containers"
    m."ms-vscode".cpptools
    m."ms-vscode"."makefile-tools"
    m.mtxr.sqltools
    m.mtxr."sqltools-driver-pg"
    m.mtxr."sqltools-driver-sqlite"
    m.nefrob."vscode-just-syntax"
    m.ozzafar.debugmcpextension
    m.pflannery."vscode-versionlens"
    m.platformio."platformio-ide"
    m.pycqa."bandit-pycqa"
    m.redhat."vscode-xml"
    m.redhat."vscode-yaml"
    m.rohaquinlop.complexipy
    m."rust-lang"."rust-analyzer"
    m.ryanluker."vscode-coverage-gutters"
    m.saoudrizwan."claude-dev"
    m.sqlfluff."vscode-sqlfluff"
    m.streetsidesoftware."code-spell-checker"
    m.stylelint."vscode-stylelint"
    m.sumneko.lua
    m.svelte."svelte-vscode"
    m.tamasfe."even-better-toml"
    m.timonwong.shellcheck
    m.vitest.explorer
    m.vue.volar
  ];
in
{
  den.aspects.editors = {
    # vscodium-fhs bundles electron_39 (insecure/EOL); -fhs kept because the
    # extension set ships many native binaries (pylance/debugpy/cpptools/...).
    includes = [
      # electron_39 — EOL/insecure; bundled in vscodium-fhs
      (den.batteries.insecure [ "electron-39.8.10" ])
      # VS Code Microsoft extensions (ms-*) — unfree (proprietary Microsoft licenses)
      (den.batteries.unfree [
        "vscode-extension-ms-azuretools-vscode-containers"
        "vscode-extension-ms-azuretools-vscode-docker"
        "vscode-extension-ms-playwright-playwright"
        "vscode-extension-ms-python-debugpy"
        "vscode-extension-ms-python-isort"
        "vscode-extension-ms-python-python"
        "vscode-extension-ms-python-vscode-pylance"
        "vscode-extension-ms-python-vscode-python-envs"
        "vscode-extension-ms-toolsai-datawrangler"
        "vscode-extension-ms-toolsai-jupyter"
        "vscode-extension-ms-toolsai-jupyter-keymap"
        "vscode-extension-ms-toolsai-jupyter-renderers"
        "vscode-extension-ms-toolsai-vscode-jupyter-cell-tags"
        "vscode-extension-ms-toolsai-vscode-jupyter-slideshow"
        "vscode-extension-ms-vscode-cpptools"
        "vscode-extension-ms-vscode-makefile-tools"
        "vscode-extension-ms-vscode-remote-remote-containers"
      ])
    ];
    nixos =
      { pkgs, ... }:
      {
        # nix-vscode-extensions overlay exposes pkgs.nix-vscode-extensions.*.
        nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
      };
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        repo = config.dotfilesRepo;
      in
      {
        programs.neovim = {
          enable = true;
          defaultEditor = true;
        };
        programs.helix.enable = true;

        # Authored (store-managed) editor configs - byte-identical from the repo.
        xdg.configFile."nvim".source = config.dots.src "nvim/.config/nvim";
        xdg.configFile."helix".source = config.dots.src "helix/.config/helix";

        home.packages = [
          pkgs.zed-editor-fhs
          (pkgs.vscode-with-extensions.override {
            vscode = pkgs.vscodium-fhs;
            vscodeExtensions = extensions pkgs.nix-vscode-extensions.vscode-marketplace;
          })
        ];

        # Mutable (two-way) vscodium config symlinked into the repo checkout.
        xdg.configFile."VSCodium/User/settings.json".source =
          config.dots.link "vscodium/.config/VSCodium/User/settings.json";
        xdg.configFile."VSCodium/User/keybindings.json".source =
          config.dots.link "vscodium/.config/VSCodium/User/keybindings.json";
        xdg.configFile."VSCodium/User/argv.json".source =
          config.dots.link "vscodium/.config/VSCodium/User/argv.json";
        xdg.configFile."VSCodium/User/globalStorage/storage.json".source =
          config.dots.link "vscodium/.config/VSCodium/User/globalStorage/storage.json";
        xdg.configFile."VSCodium/User/globalStorage/zokugun.sync-settings/settings.yml".source =
          config.dots.link "vscodium/.config/VSCodium/User/globalStorage/zokugun.sync-settings/settings.yml";
        xdg.configFile."zed/settings.json".source = config.dots.link "zed/.config/zed/settings.json";
      };
  };
}
