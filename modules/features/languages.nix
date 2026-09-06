# Languages aspect - rust (overlay toolchain), go, fnm (node), python3, jdk,
# texlive, language servers. Replaces imperative rustup/fnm init (tasks 6.1).
{ den, ... }:
{
  den.aspects.languages = {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [
          go
          fnm
          python3
          nodejs
          pnpm
          jdk
          texlive.combined.scheme-full
          rustup
          gopls
          nil
          nixfmt-rfc-style
          marksman
        ];

        programs.java.enable = true;

        # Rust cargo config (store-managed).
        home.file.".cargo/config.toml".source = config.dots.src "rust/.cargo/config.toml";
      };
  };
}
