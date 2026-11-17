---
title: PostGIS
sidebar: { order: 4 }
---

采用 docker-compose 容器编排方式部署。PostGIS 面向企业空间业务，当前镜像含 pgRouting 3.7.1。初始化 SQL 仅在空数据目录首次启动时执行。

需要纯 PostgreSQL、不启用空间扩展时，请改用 [PostgreSQL](/middleware/postgres/)。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- 可访问交付物中的 `gis.sql`（创建 `tsingyun_gis` 库及初始化 SQL）。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Database/postgis/{data,init}
```

## 准备初始化 SQL

将 `gis.sql` 下载到 init 目录：

```bash
wget https://file.tsingyun.link/docker/Database/postgres/docker-compose/gis.sql \
  -P /home/application/Database/postgis/init
```

该脚本会创建 `tsingyun_gis` 数据库并写入初始化数据。

## 编写 docker-compose.yml

编辑 `/home/application/Database/postgis/docker-compose.yml`。生产环境请将密码改成自己的密钥，不要使用文档中的占位符。

```yaml
services:
  postgis:
    container_name: postgis
    image: {{ image.amd64.reference }}
    networks:
      - tsingyun
    environment:
      TZ: Asia/Shanghai
      POSTGRES_HOST_AUTH_METHOD: md5
      POSTGRES_PASSWORD: YOUR_POSTGRES_PASSWORD
    volumes:
      - /home/application/Database/postgis/data:/var/lib/postgresql/data
      - /home/application/Database/postgis/init:/docker-entrypoint-initdb.d/
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
cd /home/application/Database/postgis
docker-compose up -d
docker-compose ps
```

## 验证

进入容器并切换到 `postgres` 用户：

```bash
docker exec -it postgis bash
su - postgres
psql
```

用 `\l` 确认存在 `tsingyun_gis` 库后，启用扩展（必须）：

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;
```

可再查询可用的 PostGIS 相关扩展：

```sql
SELECT * FROM pg_available_extensions WHERE name LIKE 'postgis%';
```

升级前备份数据目录，并做一次恢复演练。
