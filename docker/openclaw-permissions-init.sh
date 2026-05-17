#!/bin/sh
set -eu

VENV_DIR="${VENV_DIR:-/home/node/.venvs/openclaw}"

mkdir -p \
  /home/node/.openclaw \
  /home/node/.openclaw/workspace \
  /home/node/.config/openclaw \
  /home/node/.npm-global \
  /home/node/.venvs \
  "$VENV_DIR"

chown -R node:node /home/node/.openclaw
chown -R node:node /home/node/.config/openclaw
chown -R node:node /home/node/.npm-global
chown -R node:node /home/node/.venvs

if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "Creating Python venv at $VENV_DIR..."

  find "$VENV_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

  su node -c "python3 -m venv '$VENV_DIR'"
  su node -c "'$VENV_DIR/bin/python' -m pip install --upgrade pip setuptools wheel uv"
else
  echo "Python venv already exists: $VENV_DIR"
fi

su node -c "'$VENV_DIR/bin/python' --version"
su node -c "'$VENV_DIR/bin/pip' --version"

echo "OpenClaw permissions and Python venv ready."