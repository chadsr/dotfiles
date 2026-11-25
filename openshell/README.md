## Layout

| File (under `openshell/`) | Role |
| --- | --- |
| `.local/bin/oc` | Entry point: gateway token (`docker-mcp-token`, docker package), reconcile, sync in, OpenCode TUI, sync out. |
| `.local/bin/oc-sync` | `push` and `pull`: git bundle plus worktree in, commits plus edits out. |
| `.local/bin/oc-stop` | Syncs out, then stops the sandbox of a directory. |
| `.local/bin/opencode-sandbox` | `--setup`: profiles and providers. Otherwise the reconciler: image and sandbox. |
| `.local/lib/oc-sync/*.sh` | Sandbox side of `oc-sync` and `opencode-sandbox` (POSIX sh): sent as the text of `sh -c`, nothing is installed in the sandbox. |
| `.config/openshell/gateway.toml` | OpenShell gateway: Docker driver pinned, host gateway 172.17.0.1. |
| `.config/openshell/policies/opencode.yaml` | Sandbox policy: egress allowlist (OpenCode, mise) and filesystem policy. |
| `.config/openshell/profiles/mcp-gateway.yaml` | Provider profile for the MCP gateway token; holds the MCP tool allowlist. |
| `.config/openshell/profiles/zai-coding-plan.yaml` | Provider profile for the Z.ai coding plan API key. |
| `.config/openshell/images/opencode/Dockerfile` | Sandbox image `openshell-opencode:v2`: the official OpenCode image plus git, mise and the pinned DCP plugin. |
| `.config/openshell/images/opencode/sandbox.jsonc` | Sandbox-only OpenCode config: the MCP server, wired through placeholders. |
| `../docker/.config/systemd/user/docker-mcp-gateway.*` | Socket-activated MCP gateway: listener on 172.17.0.1:8811, proxy that exits after 5 idle minutes, gateway on 172.17.0.1:18811 serving the `dev-tools` servers. |
| `README.md` | This file. Stays in the repo: stow ignores `README.*`. |

## How it works

```text
once   opencode-sandbox --setup    profiles linted, imported or updated; missing providers created
|                                    secret: pass -> provider store (encrypted, host side only)
oc <dir>
| token  docker-mcp-token (docker package): pass -> $XDG_RUNTIME_DIR/docker-mcp-gateway/token, when it is missing
| recon  opencode-sandbox <dir>  (builds openshell-opencode:v2 when missing; replaces a sandbox
|          whose image, policy or profiles changed, unless it still holds unsynced work)
|          sandbox   create when missing (providers, policy; no mounts)
| push   oc-sync push <dir>
|          git bundle of the checked-out branch -> a checkout at /sandbox/<base>, same branch
|          and commit; then the tracked and not-ignored files (uncommitted edits included)
|          ~/.agents/skills -> /sandbox/.agents/skills; the opencode config entries ->
|          /sandbox/.config/opencode (both replaced); then mise trust && mise install
| run    openshell sandbox exec oc-<base>-<hash5> --workdir /sandbox/<base>/<subdir> -- opencode
| pull   oc-sync pull <dir>
|          agent commits -> the same branch; uncommitted edits -> one patch on the host worktree
| egress the sandbox sees openshell:resolve:env:... placeholders only; the proxy restores
|        the real value for the profile's exact host/port/path
| MCP    host.openshell.internal:8811/mcp -> docker-mcp-gateway.socket ->
|        docker-mcp-gateway-proxy.service -> docker-mcp-gateway.service -> MCP containers
```

`pull` fast-forwards the branch unless the host moved since the push; then the commits stay on
`refs/oc-sync/<sandbox>` (`git merge oc-sync/<sandbox>`). The patch is applied with `git apply --reject`:
hunks that clash with your own edits are left in `<file>.rej` files. A submodule is a plain directory in
the sandbox: its edits come back the same way, uncommitted in your submodule.

## Usage

```sh
oc [dir]                            # reconcile, sync in, OpenCode TUI, sync out ([dir] defaults to .)
oc-stop [dir]                       # sync out, then stop that sandbox
oc-sync pull <dir> [--dry-run]      # only bring the sandbox's commits and edits back
oc-sync push <dir> [--dry-run]      # only send the host state (pulls first after an interrupted session)
opencode-sandbox --print <dir>      # sandbox name and its workdir
opencode-sandbox --rebuild [dir]    # after changing the image, sandbox.jsonc or the plugin pin
opencode-sandbox --setup            # once after stowing, and after editing a profile
```

## Secrets and rotation

`pass` is the only place you store a secret. To rotate, edit the entry first, then the provider:

```sh
openssl rand -hex 32 | pass insert -e openshell/MCP_GATEWAY_AUTH_TOKEN
pass insert openshell/ZAI_CODING_PLAN_API_KEY
MCP_GATEWAY_AUTH_TOKEN=$(pass show openshell/MCP_GATEWAY_AUTH_TOKEN) openshell provider update mcp-gateway --credential MCP_GATEWAY_AUTH_TOKEN --wait
ZAI_CODING_PLAN_API_KEY=$(pass show openshell/ZAI_CODING_PLAN_API_KEY) openshell provider update zai-coding-plan --credential ZAI_CODING_PLAN_API_KEY --wait
```

A rotated gateway token also needs its file rewritten (`docker-mcp-token --refresh`).

`stable_placeholder: true` lets a rotated value reach running sessions without a restart, but a
stale in-sandbox `opencode serve` can still answer MCP 401 until it is restarted.

## Changing things

### Add a provider profile

Copy `profiles/zai-coding-plan.yaml`: `id:` on its own line, an inline `env_vars: [VAR]`. Add a pass entry
named `openshell/<VAR>`, then run `opencode-sandbox --setup`.

### Change the MCP allowlist

Edit `rules` (allowed) or `deny_rules` (denied; they win) in `profiles/mcp-gateway.yaml`, then run
`opencode-sandbox --setup`, which also lints the profiles.

### Change the egress policy

Edit `policies/opencode.yaml`. Do not add the MCP endpoint here: the provider contributes it.
The `mise` rule also covers the processes mise starts, and each download host needs its own endpoint.
The npm registry entry only serves plugin updates (it needs `allow_encoded_slash`); the plugin pin
is `DCP_PLUGIN_VERSION` in the Dockerfile.

Any edit to a profile or the policy makes the next `oc` recreate the sandbox, so do it between sessions.

### Change what runs in the sandbox

Edit a file in `.local/lib/oc-sync/`: `oc-sync` and `opencode-sandbox` send it as the text of `sh -c` each time they need it, so there is nothing to install.

## Troubleshooting

- **Gateway not listening** (a launch warns `docker-mcp-gateway.socket is not listening`; the units are the docker package's):

  ```sh
  systemctl --user status docker-mcp-gateway.socket
  systemctl --user enable --now docker-mcp-gateway.socket
  ```

- **`ERROR: no pass entry …`** (`docker-mcp-token` behind `oc`) or **`ERROR: missing pass entry …`** (`--setup`): create it as shown above, then run the command again.
- **`ERROR: docker-mcp-token not found on PATH`** (`oc`): stow the docker package.
- **`no gateway token`** (a warning from `opencode-sandbox`, an error from `oc`): run `docker-mcp-token`.
- **`ERROR: provider … not found`**: run `opencode-sandbox --setup`.
- **`… holds unsynced work`**: run `oc-sync pull <dir>` first, or delete the state file it names to
  discard that work.
- **`oc-sync pull failed`**: the sandbox keeps its work. Fix the cause, then `oc-sync pull <dir>`.
- **`*.rej` files after a pull**: the agent changed lines you had changed too. Merge them by hand; the
  whole patch is kept as `~/.local/state/oc-sync/<sandbox>.rejected.patch`.
- **A tool is not installed** (`mise install` warns at each push): run it inside the sandbox.
- **MCP 401 after a rotation**: run `docker-mcp-token --refresh`, then restart the in-sandbox `opencode serve`.

## Limits

- The sandbox is a snapshot: host edits reach it at the next `oc`, and its work reaches the host only
  through a pull.
- gitignored files are not sent. The first push for a sandbox uploads the full history; every push
  resends the whole worktree. A submodule's own history is not in the sandbox.
- A rebuilt image, or a changed policy, profile or layout, replaces the sandbox; what was not pulled is gone.
- No push to GitHub from inside (no route for OpenCode, GitHub write tools denied): commits leave
  through `pull`.
- `basedpyright-langserver` is not in the image: the shared `opencode.jsonc` needs the repository
  to provide it through mise or uv.
- MCP servers run outside the sandbox, only while a sandbox has an MCP session open.
- The gateway's 8 internal tools cannot be disabled alongside `--profile`: `deny_rules` are the control.
