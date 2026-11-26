# OpenShell

> Run OpenCode for a git repository inside an OpenShell sandbox: your working
> tree goes in, and the agent's work comes back when you quit.

## Quick start

You need the `openshell` CLI with its gateway running, Docker and `pass`. The
MCP servers also need the `docker` package.

```sh
# 1. the two secrets (once)
openssl rand -hex 32 | pass insert -e openshell/MCP_GATEWAY_AUTH_TOKEN
pass insert openshell/ZAI_CODING_PLAN_API_KEY
# 2. the profiles and providers (once)
stow openshell && oc setup
# 3. a session, from anywhere inside a git repository
oc
```

The first `oc` builds the image `openshell-opencode` and creates the sandbox.
OpenCode works on a copy of the repository; when you quit, the agent's commits
land on your branch and its uncommitted edits on your working tree.

## Usage

| Command            | Does                                                  |
| ------------------ | ----------------------------------------------------- |
| `oc [dir]`         | Sync in, run OpenCode, sync out.                      |
| `oc pull [dir]`    | Bring the sandbox's commits and edits back.           |
| `oc push [dir]`    | Send your branch and uncommitted files.               |
| `oc stop [dir]`    | Sync out, then stop the sandbox.                      |
| `oc rebuild [dir]` | Rebuild the image; a new image replaces the sandbox.  |
| `oc setup`         | Import or update the profiles; run after editing one. |

`[dir]` defaults to the current directory. One session per repository at a
time: a second `oc` there stops at a lock.

## How it works

1. **In:** the commits of your branch as a git bundle, then the tracked and
   not-ignored files, uncommitted edits included. Your `~/.agents/skills` and
   OpenCode config are copied in too, and `mise install` runs for the
   repository's tools.
2. **Run:** OpenCode in the sandbox, with nothing mounted and placeholders
   instead of secrets. MCP servers stay on the host, behind the allowlist of
   the `mcp-gateway` profile.
3. **Out:** the agent's commits fast-forward your branch, or wait on
   `refs/oc-sync/<sandbox>` for a `git merge` when your branch moved since
   launch. Its uncommitted edits come back as one patch; a hunk that clashes
   with your own edits is left in a `<file>.rej` file.

## Configuration

Everything lives in `.config/openshell/`. The code is `.local/bin/oc` and its
sandbox side, `.local/lib/oc/sandbox.sh`.

| To change              | Edit                        | Then         |
| ---------------------- | --------------------------- | ------------ |
| The MCP tool allowlist | `profiles/mcp-gateway.yaml` | `oc setup`   |
| Allowed network access | `policies/opencode.yaml`    | `oc`         |
| The sandbox image      | `images/opencode/`          | `oc rebuild` |

In the profile, `deny_rules` win over `rules`. Do not add the MCP endpoint to
the policy: the profile contributes it.

> [!IMPORTANT]
> A changed image, policy or profile makes the next `oc` replace the sandbox,
> and work that was not pulled is gone with it. `oc` refuses while the sandbox
> holds unsynced work.

## Secrets

`pass` is the only place a secret is stored. `oc setup` creates each provider
from the `pass` entry `openshell/<ENV_VAR>` named in its profile.

To rotate a value, update the `pass` entry first, then the provider:

```sh
export MCP_GATEWAY_AUTH_TOKEN="$(pass show openshell/MCP_GATEWAY_AUTH_TOKEN)"
openshell provider update mcp-gateway --credential MCP_GATEWAY_AUTH_TOKEN --wait
```

The API key rotates the same way: `ZAI_CODING_PLAN_API_KEY` and
`zai-coding-plan`.

The gateway reads its token file only at start, so a rotated gateway token
also needs this (restart a running `opencode serve` in the sandbox too):

```sh
docker-mcp-token --refresh && \
  systemctl --user restart docker-mcp-gateway.service
```

## Troubleshooting

- **`WARNING: no gateway token` or `WARNING: docker-mcp-token not found`**:
  MCP is refused, the session still runs. Stow the `docker` package and start
  the gateway socket:

  ```sh
  systemctl --user enable --now docker-mcp-gateway.socket
  ```

- **`ERROR: missing pass entry openshell/<VAR>`**: add it with
  `pass insert openshell/<VAR>`, then run `oc setup` again.
- **MCP 403 in the sandbox** (`Version negotiation failed`):
  `openshell logs <sandbox> --source sandbox | grep DENIED` prints the denied
  protocol version or method. Allow it in `profiles/mcp-gateway.yaml` and run
  `oc setup`.
- **`… holds unsynced work`**: the sandbox has work that is not on the host
  yet. `oc pull <dir>` brings it back; delete the state file it names to
  discard it.
- **`ERROR: the work is still in sandbox …`**: nothing is lost. Fix the cause,
  then run `oc pull <dir>`.
- **`*.rej` files**: the agent changed lines you had changed too. Merge them by
  hand; the whole patch is kept as
  `~/.local/state/oc-sync/<sandbox>.rejected.patch`.

## Limits

- Host edits reach the sandbox at the next `oc`; the sandbox's work reaches
  the host only through a pull.
- gitignored files are not sent.
- A submodule goes in as a plain directory: its files are there, but edits
  inside it do not come back.
- The agent cannot push to GitHub from inside the sandbox. Commits leave
  through a pull.
- `basedpyright-langserver` is not in the image; a repository that needs it
  must provide it through mise or uv.
