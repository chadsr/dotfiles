# GPG aspect - programs.gpg settings, gnupg config files, the custom pinentry
# scripts, wayprompt, and the gnupghome/ssh-auth-sock user services. pcscd and
# the OS-level agent live on the nixos side. The shared key id is declared once.
{ den, ... }:
let
  gpgKey = "0x2B7340DB13C85766";
in
{
  den.aspects.gpg = {
    nixos = {
      services.pcscd.enable = true;
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # GPG key provisioning (spec: secrets-management): import the committed
        # public key and set TOFU trust `good` before sops decryption or git
        # signing runs. The private key lives on the Yubikey.
        home.activation.provision-gpg-key = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      if ! ${pkgs.gnupg}/bin/gpg --list-keys ${gpgKey} >/dev/null 2>&1; then
                        ${pkgs.gnupg}/bin/gpg --import ${../../data/gpg/2B7340DB13C85766.asc} >/dev/null 2>&1 || true
                        echo -e "trust-model tofu+pgp\ntrusted-key ${gpgKey}" >> "$HOME/.gnupg/gpg.conf" 2>/dev/null || true
                        ${pkgs.gnupg}/bin/gpg --command-fd 0 --edit-key ${gpgKey} <<EOF || true
          trust
          5
          y
          save
          EOF
                      fi
        '';

        programs.gpg = {
          enable = true;
          settings = {
            personal-cipher-preferences = "AES256 AES192 AES";
            personal-digest-preferences = "SHA512 SHA384 SHA256";
            personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
            default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
            cert-digest-algo = "SHA512";
            s2k-digest-algo = "SHA512";
            s2k-cipher-algo = "AES256";
            charset = "utf-8";
            no-comments = true;
            no-emit-version = true;
            no-greeting = true;
            keyid-format = "0xlong";
            list-options = "show-uid-validity";
            verify-options = "show-uid-validity";
            with-fingerprint = true;
            require-cross-certification = true;
            no-symkey-cache = true;
            armor = true;
            use-agent = true;
            throw-keyids = true;
            default-key = gpgKey;
            trusted-key = gpgKey;
            trust-model = "tofu+pgp";
          };
        };

        # gpg-agent config: static pinentry-program into the deployed pinentry-auto
        # script (runtime-appended line in the old setup is folded in statically).
        home.file.".gnupg/gpg-agent.conf".text = ''
          enable-ssh-support
          ttyname $GPG_TTY
          default-cache-ttl 60
          max-cache-ttl 120
          pinentry-program ${config.home.homeDirectory}/.local/bin/pinentry-auto
        '';
        home.file.".gnupg/scdaemon.conf".source = config.dots.src "gpg/.gnupg/scdaemon.conf";
        home.file.".gnupg/common.conf".source = config.dots.src "gpg/.gnupg/common.conf";
        home.file.".gnupg/sshcontrol".source = config.dots.src "gpg/.gnupg/sshcontrol";

        # Custom pinentry scripts (store-managed; pinentry-auto picks the right
        # pinentry for the active context).
        home.file.".local/bin/pinentry-auto".source = config.dots.src "gpg/.local/bin/pinentry-auto";
        home.file.".local/bin/pinentry-fuzzel".source = config.dots.src "gpg/.local/bin/pinentry-fuzzel";

        xdg.configFile."wayprompt/config.ini".source = config.dots.src "gpg/.config/wayprompt/config.ini";

        # User services that export GNUPGHOME and SSH_AUTH_SOCK into the session.
        systemd.user.services.gnupghome = {
          Unit.Description = "Set GNUPGHOME Environment Variable";
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash -c 'systemctl --user set-environment GNUPGHOME=\"\${GNUPGHOME:-$HOME/.gnupg}\"'";
          };
          Install.WantedBy = [ "default.target" ];
        };
        systemd.user.services.ssh-auth-sock = {
          Unit.Description = "Set SSH_AUTH_SOCK to GnuPG agent";
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash -c 'systemctl --user set-environment SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)'";
          };
          Install.WantedBy = [ "default.target" ];
        };

        home.packages = with pkgs; [
          pinentry-gtk2
          pinentry-tty
          yubikey-touch-detector
        ];

        # yubikey-touch-detector config + socket (touch notifications).
        xdg.configFile."yubikey-touch-detector/service.conf".source =
          config.dots.src "yubikey/.config/yubikey-touch-detector/service.conf";
        systemd.user.sockets.yubikey-touch-detector = {
          Unit = {
            Description = "Yubikey touch detector socket";
          };
          Socket = {
            ListenStream = "%t/yubikey-touch-detector.socket";
          };
          Install.WantedBy = [ "default.target" ];
        };
        systemd.user.services.yubikey-touch-detector = {
          Unit = {
            Description = "Yubikey touch detector";
          };
          Service = {
            Type = "simple";
            Restart = "always";
            ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
          };
          Install.WantedBy = [ "default.target" ];
        };

        # SSH Yubikey public key.
        home.file.".ssh/yk.pub".source = config.dots.src "ssh/.ssh/yk.pub";

        # pass store two-way bind: ~/.password-store symlinks into the repo so
        # `pass insert`/`edit`/`git` write through (entries are GPG-encrypted by
        # pass already; NOT a sops secret — per secrets-management spec).
        home.file.".password-store".source = config.dots.link "pass/.password-store";
      };
  };
}
