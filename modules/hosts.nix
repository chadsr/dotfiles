# Entity declarations. Each line declares a host (and its user) for a platform;
# den auto-creates the matching host + user aspects, which other files enhance.
# Freeform host attributes (disk, ramMiB, dotfilesRepo) carry per-host data that
# aspects read via `host.disk` / `host.ramMiB` / `host.dotfilesRepo`.
{ den, ... }:
{
  den.hosts.x86_64-linux.thinky = {
    users.marvin = { };
    # Filled at install time.
    disk = "/dev/nvme0n1";
    ramMiB = 16384;
    dotfilesRepo = "/home/marvin/git/github.com/chadsr/dotfiles";
  };

  den.hosts.x86_64-linux.shifty = {
    users.marvin = { };
    # Filled at install time.
    disk = "/dev/nvme0n1";
    ramMiB = 32768;
    dotfilesRepo = "/home/marvin/git/github.com/chadsr/dotfiles";
  };

  den.hosts.aarch64-darwin.macy = {
    users.marvin = { };
    dotfilesRepo = "/Users/marvin/git/github.com/chadsr/dotfiles";
  };
}
