# Secrets manifest — maps each sops secret key to its on-disk target path with
# owner/group/mode. Consumed by modules/features/secrets.nix to generate the
# sops.secrets declarations. Paths match the former store-secrets.sh:105-125
# targets. App-config secrets use Linux paths (these apps are Linux-only); the
# marvin password + LUKS secrets are root-owned system secrets.
#
# Populate the placeholder values via `sops secrets/secrets.yaml` (decrypts with
# the Yubikey) by pasting the content of the former data/**/*.asc.gpg files.
{
  # marvin login password (yescrypt hash) — consumed by hashedPasswordFile.
  "marvin-hashed-password" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # LUKS recovery (disko keyfile-cascade, design D13). root-owned.
  "luks-root-passphrase" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
  "luks-secondary-keyfile" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # sunsetr geo — shared across both Linux hosts.
  "sunsetr/geo.toml" = {
    path = "/home/marvin/.config/sunsetr/geo.toml";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };

  # waybar-crypto config (CoinMarketCap API key + display settings).
  "waybar-crypto/config.ini" = {
    path = "/home/marvin/.config/waybar-crypto/config.ini";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };

  # App-config secrets (Linux-only apps).
  "gallery-dl/config.json" = {
    path = "/home/marvin/.config/gallery-dl/config.json";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "gtk-3.0/bookmarks" = {
    path = "/home/marvin/.config/gtk-3.0/bookmarks";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "khal/config" = {
    path = "/home/marvin/.config/khal/config";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "nextcloud/nextcloud.cfg" = {
    path = "/home/marvin/.config/Nextcloud/nextcloud.cfg";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "qBittorrent/categories.json" = {
    path = "/home/marvin/.config/qBittorrent/categories.json";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "tidal-hifi/config.json" = {
    path = "/home/marvin/.config/tidal-hifi/config.json";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "vdirsyncer/config" = {
    path = "/home/marvin/.config/vdirsyncer/config";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "ssh/config" = {
    path = "/home/marvin/.ssh/config";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "radicle/keys/radicle" = {
    path = "/home/marvin/.radicle/keys/radicle";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
  "android/keystore-rossch" = {
    path = "/home/marvin/.android/keystores/keystore-rossch";
    owner = "marvin";
    group = "users";
    mode = "0600";
  };
}
