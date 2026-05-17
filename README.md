# openclaw-stack

`openclaw-stack` 是一个面向 OpenClaw 的 Docker Compose 运行栈，基于 `ghcr.io/openclaw/openclaw:latest` 镜像扩展了常用工具、持久化目录、权限初始化以及网关启动流程。

## 组成

- `Dockerfile`：在官方 OpenClaw 镜像上安装常用工具和初始化脚本。
- `docker-compose.yml`：定义三个服务。
- `docker/openclaw-permissions-init.sh`：首次启动前准备目录权限和 Python venv。
- `docker/openclaw-gateway-entrypoint.sh`：初始化网关配置并启动 OpenClaw gateway。

## 服务

- `openclaw-permissions`：一次性初始化容器，创建目录并修正权限。
- `openclaw-gateway`：主服务，提供网关和桥接端口。
- `openclaw-cli`：共享网关网络的交互式 CLI 容器。

## 前置条件

- Docker
- Docker Compose
- 可写的数据目录，用于持久化配置、工作区、认证信息、npm 全局包和 Python venv

## 快速开始

1. 准备环境变量文件 `.env`。
2. 确保 `OPENCLAW_DATA_DIR` 指向一个存在且可写的目录。
3. 启动服务：

```bash
docker compose up -d
```

4. 查看网关状态：

```bash
docker compose ps
docker compose logs -f openclaw-gateway
```

## 默认端口

- `18789`：OpenClaw gateway
- `18790`：bridge

如果需要改端口，可以在 `.env` 中设置：

```env
OPENCLAW_GATEWAY_PUBLIC_PORT=18789
OPENCLAW_BRIDGE_PUBLIC_PORT=18790
```

## 重要环境变量

- `OPENCLAW_IMAGE`：要使用的镜像，默认 `ghcr.io/flyinghail/openclaw-stack:latest`
- `OPENCLAW_ENV_FILE`：Compose 读取的环境文件，默认 `.env`
- `OPENCLAW_DATA_DIR`：持久化数据根目录
- `OPENCLAW_TZ`：容器时区，默认 `UTC`
- `OPENCLAW_GATEWAY_BIND`：网关绑定地址，默认 `lan`
- `OPENCLAW_GATEWAY_TOKEN`：必须提供，网关启动时会校验
- `OPENCLAW_CONTROL_UI_ORIGINS`：额外允许的 UI 来源，逗号分隔
- `OPENCLAW_DISABLE_BONJOUR`：默认 `1`

## 持久化目录

Compose 会把以下内容挂载到 `OPENCLAW_DATA_DIR` 下：

- `config`
- `workspace`
- `auth-profile-secrets`
- `npm-global`
- `venv-openclaw`

这些目录不要放在临时路径里，否则重启后状态会丢失。

## 构建镜像

```bash
docker build -t openclaw-stack:latest .
```

如果要推送到 GHCR，可以参考仓库里的 GitHub Actions workflow：`.github/workflows/docker-publish.yml`。

## 常见问题

### 启动时报 `OPENCLAW_GATEWAY_TOKEN is required`

请在 `.env` 中设置 `OPENCLAW_GATEWAY_TOKEN`，否则网关入口脚本会直接退出。

### 首次启动较慢

首次启动会创建 Python venv、初始化配置并修正目录权限，属于正常现象。

### 想重置初始化状态

删除 `OPENCLAW_DATA_DIR/config/.docker-init-ok`，下次启动会重新执行首次初始化逻辑。

