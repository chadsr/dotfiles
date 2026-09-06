# Git aspect - programs.git with signing (Yubikey GPG key), delta pager, and the
# full alias/extraConfig set lifted from the former stow package.
{ den, ... }:
let
  signingKey = "98B1F6BDC25DDD2560398F212B7340DB13C85766";
in
{
  den.aspects.git = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        programs.git = {
          enable = true;
          userName = "Ross";
          userEmail = "git@ross.ch";

          signing = {
            key = signingKey;
            signByDefault = true;
          };

          ignores = [
            # Lifted from git/.config/git/ignore
            ".direnv"
            ".envrc"
            "result"
            "result-*"
          ];

          aliases = {
            a = "add";
            ap = "add -p";
            amend = "commit --amend --no-edit";
            br = "branch";
            brd = "branch -d";
            brD = "branch -D";
            cl = "clone";
            cm = "commit -m";
            co = "switch";
            cob = "switch -c";
            sw = "switch -";
            cp = "cherry-pick";
            d = "diff";
            dc = "diff --cached";
            ds = "diff --stat";
            gr = "grep -Ii";
            p = "push";
            pl = "pull";
            rs = "restore";
            s = "status -sb";
            st = "stash push";
            stp = "stash pop";
            rba = "rebase --abort";
            rbc = "rebase --continue";
            cmns = "commit --no-gpg-sign -m";
            coo = "!git fetch && git switch";
            fea = "fetch --all --prune";
            la = "!git config -l | grep alias | cut -c 7-";
            pf = "push --force-with-lease";
            undocommit = "reset --soft HEAD^";
            rrc = "rerere clear";
            rrd = "rerere diff";
            rrf = "!git rerere forget .";
            rrg = "rerere gc";
            rrs = "rerere status";
            lgs = "!git lg --stat";
            b = "!git for-each-ref --sort='-committerdate' --format='%(committerdate:short)%09%(objectname:short)%09%(refname:short)' refs/heads | column -t";
            brdr = "!f() { if [ $# -eq 1 ]; then git push origin --delete \"$1\"; else git push \"$1\" --delete \"$2\"; fi; }; f";
            f = "!git ls-files | grep -i";
            fixup = "!f() { t=\${1:-HEAD}; git rev-parse --verify \"$t^{commit}\" >/dev/null 2>&1 || { echo \"error: $t is not a valid commit\" >&2; exit 1; }; git rev-parse --verify \"$t^\" >/dev/null 2>&1 || { echo \"error: $t is the root commit, cannot fix up\" >&2; exit 1; }; b=$(git rev-parse \"$t^\"); echo \"Fixing up: $(git log -1 --format='%h %s' \"$t\")\"; git commit --fixup=$t && GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash $b; }; f";
            lg = "log --graph --decorate --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
            rb = "!r=$(git remote get-url upstream >/dev/null 2>&1 && echo upstream || echo origin); git fetch \"$r\" && git remote set-head \"$r\" -a 2>/dev/null; git rebase --rebase-merges=no-rebase-cousins \"$r/HEAD\"";
            rbi = "!f() { r=$(git remote get-url upstream >/dev/null 2>&1 && echo upstream || echo origin); git rebase -i \"\${1:-$r/HEAD}\"; }; f";
            rl = "reflog --pretty=format:'%Cred%h%Creset %C(yellow)%gd%C(reset) %C(auto)%gs%C(reset) %C(green)(%cr)%C(reset) %C(bold blue)<%an>%Creset' --abbrev-commit";
            stl = "stash list --pretty=format:'%C(red)%h%C(reset) - %C(yellow)(%gd%C(yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)'";
            unresolve = "!git checkout --conflict=$(git config merge.conflictStyle || echo merge)";
            lfs = "!git lfs install --local && git lfs pull";
          };

          delta = {
            enable = true;
            options = {
              navigate = true;
              # features is owned by the catppuccin delta theme (theming aspect).
              interactive = {
                keep-plus-minus-markers = false;
              };
              decorations = {
                commit-style = "raw";
                file-style = "omit";
                hunk-header-style = "file line-number syntax";
              };
            };
          };

          extraConfig = {
            core = {
              pager = "delta";
              fsmonitor = true;
              untrackedCache = true;
            };
            init.defaultBranch = "main";
            # interactive.diffFilter owned by the delta module.
            gpg.format = "openpgp";
            credential.helper = "cache timeout=14400";
            diff = {
              colorMoved = "default";
              mnemonicprefix = true;
            };
            merge = {
              conflictstyle = "zdiff3";
              tool = "nvimdiff3";
            };
            mergetool = {
              prompt = false;
              keepBackup = false;
            };
            rebase = {
              autoStash = true;
              autoSquash = true;
              updateRefs = true;
              missingCommitsCheck = "warn";
              stat = true;
            };
            pull.rebase = true;
            push = {
              default = "simple";
              autoSetupRemote = true;
              useForceIfIncludes = true;
              followTags = true;
            };
            fetch.prune = true;
            log = {
              followMerges = true;
              mailmap = true;
            };
            rerere.enabled = true;
            tag = {
              forceSignAnnotated = true;
              sort = "version:refname";
            };
            help.autocorrect = "prompt";
            branch.sort = "-committerdate";
            url = {
              "git@github.com:" = {
                insteadOf = "gh:";
                pushInsteadOf = "https://github.com/";
              };
              "git@gist.github.com:" = {
                insteadOf = "gist:";
                pushInsteadOf = "https://gist.github.com/";
              };
              "git@gitlab.com:" = {
                insteadOf = "gl:";
                pushInsteadOf = "https://gitlab.com/";
              };
            };
          };
        };

        # delta must be installed for programs.git.delta to work.
        home.packages = [ pkgs.delta ];
      };
  };
}
