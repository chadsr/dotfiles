# Custom OpenCode sandbox image for OpenShell. See openshell/README.md.
# uid 1000 gets a passwd entry and owns /sandbox: OpenShell requires one for a numeric USER.
# Repository tools (basedpyright included) come from mise/uv, not from this image.
# The base entrypoint stays: OpenShell starts a helper container from this image with no command.

# The plugin named in the shared config, installed where opencode keeps its plugin cache: a session starts
# without a cold install, and opencode still updates it itself. To bump the pin: opencode-sandbox --rebuild
FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS plugins

# hadolint ignore=DL3018
RUN apk add --no-cache nodejs npm
WORKDIR /
COPY package*.json .
RUN npm install --prefix /out --omit=dev --ignore-scripts --no-audit --no-fund

FROM ghcr.io/anomalyco/opencode:2.4.1@sha256:10e340e3e86d7b23e95cd9960f5a934beae8a87593d7398b5629b6112ed1fc63

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates git mise \
  && addgroup -g 1000 opencode \
  && adduser -D -H -u 1000 -G opencode -h /sandbox -s /bin/sh opencode \
  && mkdir -p /sandbox/.config/opencode /sandbox/.cache/opencode \
  && chown -R opencode:opencode /sandbox

COPY --chown=1000:1000 sandbox.jsonc /sandbox/opencode.jsonc
# opencode uses the newest all-digit generation directory; an update it installs lands beside this one.
COPY --chown=1000:1000 --from=plugins /out /sandbox/.cache/opencode/npm/@tarquinen/opencode-dcp@latest/1

ENV HOME=/sandbox
# `openshell sandbox exec` runs a login shell, which resets PATH: the shims go back in through profile.d.
RUN printf 'export PATH="/sandbox/.local/share/mise/shims:$PATH"\n' >/etc/profile.d/mise.sh
USER 1000
