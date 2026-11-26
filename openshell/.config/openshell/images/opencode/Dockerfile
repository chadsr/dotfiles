# OpenCode sandbox image for OpenShell. Repository tools come from mise/uv, not from this image.

# The plugin named in the shared config, pre-installed in opencode's plugin cache.
FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf AS plugins

# hadolint ignore=DL3018
RUN apk add --no-cache nodejs npm
WORKDIR /
COPY package*.json .
RUN npm install --prefix /out --omit=dev --ignore-scripts --no-audit --no-fund

FROM ghcr.io/anomalyco/opencode:2.4.1@sha256:10e340e3e86d7b23e95cd9960f5a934beae8a87593d7398b5629b6112ed1fc63

# OpenShell needs a passwd entry for a numeric USER.
# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates git mise \
  && addgroup -g 1000 opencode \
  && adduser -D -H -u 1000 -G opencode -h /sandbox -s /bin/sh opencode \
  && mkdir -p /sandbox/.config/opencode /sandbox/.cache/opencode \
  && chown -R opencode:opencode /sandbox

COPY --chown=1000:1000 sandbox.jsonc /sandbox/opencode.jsonc
# opencode uses the newest all-digit generation directory.
COPY --chown=1000:1000 --from=plugins /out /sandbox/.cache/opencode/npm/@tarquinen/opencode-dcp@latest/1

ENV HOME=/sandbox
# The login shell of `openshell sandbox exec` resets PATH: put the mise shims back.
RUN <<'EOF' cat > /etc/profile.d/mise.sh
export PATH="/sandbox/.local/share/mise/shims:$PATH"
EOF

USER 1000
