# Composite aspect bundling the cross-platform + darwin base feature set.
# darwin stateful init is scoped to GPG provisioning + system.defaults only
# (no ollama/docker/skillshare/vdirsyncer on darwin - design D8).
{ den, ... }:
{
  den.aspects.macos-base = {
    includes = [
      den.aspects.gpg
      den.aspects.git
      den.aspects.shell
      den.aspects.editors
      den.aspects.dev-tools
      den.aspects.languages
      den.aspects.theming
      den.aspects.cli-tools
      den.aspects.browser
      den.aspects.productivity
      den.aspects.secrets
      den.aspects.macos
    ];
  };
}
