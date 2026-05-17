FROM ghcr.io/openclaw/openclaw:latest

USER root

RUN set -eux; \
    apt-get update \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        git \
        curl \
        wget \
        unzip \
        zip \
        jq \
        ripgrep \
        fd-find \
        build-essential \
        ca-certificates \
        procps \
        less \
        nano \
        vim-tiny \
        openssh-client; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    rm -rf /var/lib/apt/lists/* \
    mkdir -p \
      /home/node/.openclaw \
      /home/node/.openclaw/workspace \
      /home/node/.npm-global \
      /home/node/.venvs/openclaw; \
    chown -R node:node \
      /home/node/.openclaw \
      /home/node/.npm-global \
      /home/node/.venvs

COPY --chmod=0755 docker/openclaw-gateway-entrypoint.sh /usr/local/bin/openclaw-gateway-entrypoint
COPY --chmod=0755 docker/openclaw-permissions-init.sh /usr/local/bin/openclaw-permissions-init

USER node

ENV VENV_DIR=/home/node/.venvs/openclaw
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=/home/node/.venvs/openclaw/bin:/home/node/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 这个 venv 是镜像内 fallback。
# 如果运行时挂载 /home/node/.venvs/openclaw，会被宿主机目录覆盖，
# 所以真正持久化 venv 仍然由 entrypoint/init 脚本创建。
RUN python3 -m venv "$VENV_DIR" \
    && "$VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel uv