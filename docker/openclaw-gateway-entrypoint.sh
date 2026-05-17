#!/bin/sh
set -eu

VENV_DIR="${VENV_DIR:-/home/node/.venvs/openclaw}"
NPM_PREFIX="${NPM_CONFIG_PREFIX:-/home/node/.npm-global}"

export PATH="$VENV_DIR/bin:$NPM_PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  echo "ERROR: OPENCLAW_GATEWAY_TOKEN is required."
  exit 1
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "Python venv is missing, creating at $VENV_DIR..."
  mkdir -p "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel
fi

BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
INTERNAL_PORT="18789"
INIT_MARKER="/home/node/.openclaw/.docker-init-ok"

if [ ! -f "$INIT_MARKER" ]; then
  ORIGINS_JSON="$(
    node -e '
      const publicPort =
        process.env.OPENCLAW_GATEWAY_PUBLIC_PORT ||
        process.env.OPENCLAW_GATEWAY_PORT ||
        "18789";

      const extra = (process.env.OPENCLAW_CONTROL_UI_ORIGINS || "")
        .split(",")
        .map(s => s.trim())
        .filter(Boolean);

      const origins = [
        "http://localhost:" + publicPort,
        "http://127.0.0.1:" + publicPort,
        ...extra
      ];

      console.log(JSON.stringify([...new Set(origins)]));
    '
  )"

  echo "First-time OpenClaw Docker config initialization..."
  echo "gateway.bind=${BIND}"
  echo "gateway.internalPort=${INTERNAL_PORT}"
  echo "gateway.controlUi.allowedOrigins=${ORIGINS_JSON}"

  node dist/index.js config set --batch-json \
    "[{\"path\":\"gateway.mode\",\"value\":\"local\"},{\"path\":\"gateway.bind\",\"value\":\"${BIND}\"},{\"path\":\"gateway.controlUi.allowedOrigins\",\"value\":${ORIGINS_JSON}}]"

  touch "$INIT_MARKER"
else
  echo "OpenClaw Docker config already initialized; skipping config set."
fi

exec node dist/index.js gateway \
  --bind "$BIND" \
  --port "$INTERNAL_PORT"