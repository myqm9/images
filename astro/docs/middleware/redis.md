---
title: Redis
sidebar: { order: 5 }
---

采用 docker-compose 容器编排方式部署。生产环境必须设置 Redis 密码，禁止空密码。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Database/redis/{data,logs}
```

## 编写 docker-compose.yml

编辑 `/home/application/Database/redis/docker-compose.yml`，将 `YOUR_REDIS_PASSWORD` 替换为实际密码；healthcheck 必须使用同一密码。

```yaml
services:
  redis:
    image: {{ image.amd64.reference }}
    container_name: redis
    networks:
      - tsingyun
    restart: always
    command: redis-server --requirepass YOUR_REDIS_PASSWORD --port 6379 --appendonly yes --dbfilename dump.rdb --dir /data --timeout 0 --save 900 1 --save 300 10 --save 60 10000
    environment:
      TZ: Asia/Shanghai
    volumes:
      - /home/application/Database/redis/data:/data
      - /home/application/Database/redis/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 6379:6379
    healthcheck:
      test: ["CMD", "redis-cli", "-h", "127.0.0.1", "-p", "6379", "-a", "YOUR_REDIS_PASSWORD", "ping"]
      interval: 30s
      retries: 3
      start_period: 30s
      timeout: 10s

networks:
  tsingyun:
    external: true
```

## 启动容器

```bash
cd /home/application/Database/redis
docker-compose up -d
docker-compose ps
```

预期服务名为 `redis`，端口 `0.0.0.0:6379->6379/tcp`。

## 验证

```bash
docker exec redis redis-cli -a 'YOUR_REDIS_PASSWORD' ping
```

预期输出 `PONG`。数据目录必须纳入备份。
