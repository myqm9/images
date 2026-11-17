---
title: PostgreSQL
sidebar: { order: 3 }
---

采用 docker-compose 容器编排方式部署。本文适用于单实例容器；高可用、连接池和备份策略需按业务容量设计。初始化 SQL 仅在空数据目录首次启动时执行。

需要空间扩展和 pgRouting 时，请改用 [PostGIS](/middleware/postgis/)。

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
mkdir -p /home/application/Database/postgres/{data,init}
```

如需首次启动导入 SQL，将脚本放到 `init` 目录。

## 编写 docker-compose.yml

编辑 `/home/application/Database/postgres/docker-compose.yml`。生产环境请将密码改成自己的密钥。

```yaml
services:
  postgres:
    container_name: postgres
    image: {{ image.amd64.reference }}
    networks:
      - tsingyun
    environment:
      TZ: Asia/Shanghai
      POSTGRES_HOST_AUTH_METHOD: md5
      POSTGRES_PASSWORD: YOUR_POSTGRES_PASSWORD
    volumes:
      - /home/application/Database/postgres/data:/var/lib/postgresql/data
      - /home/application/Database/postgres/init:/docker-entrypoint-initdb.d/
      - /etc/localtime:/etc/localtime:ro
    command: -c max_connections=2000
    ports:
      - "5432:5432"
    restart: always

networks:
  tsingyun:
    external: true
```

## 启动容器

```bash
cd /home/application/Database/postgres
docker-compose up -d
docker-compose ps
```

## 验证

进入容器并切换到 `postgres` 用户：

```bash
docker exec -it postgres bash
su - postgres
psql
```

用 `\l` 确认默认库存在。也可在宿主机执行：

```bash
docker exec postgres pg_isready
```

数据目录必须纳入备份与恢复演练。
