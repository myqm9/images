---
title: ClickHouse
sidebar: { order: 1 }
---

采用 docker-compose 容器编排方式部署。本文面向单节点；集群拓扑、分片和副本需另行设计。生产环境必须设置非空管理密码。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

ARM64 为鲲鹏 920 已验证版本，与 AMD64 版本号可能不同，以发布信息为准。

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Database/clickhouse/{data,log}
```

规划 HTTP 端口 `8123` 与原生协议端口 `9000`，并为数据目录和日志目录预留磁盘空间。

## 编写 docker-compose.yml

编辑 `/home/application/Database/clickhouse/docker-compose.yml`：

```yaml
services:
  clickhouse:
    image: {{ image.amd64.reference }}
    container_name: clickhouse
    restart: always
    environment:
      CLICKHOUSE_USER: default
      CLICKHOUSE_PASSWORD: YOUR_CLICKHOUSE_PASSWORD
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT: "1"
      TZ: Asia/Shanghai
    networks:
      - tsingyun
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - /home/application/Database/clickhouse/log:/var/log/clickhouse-server
      - /home/application/Database/clickhouse/data:/var/lib/clickhouse
      - /etc/localtime:/etc/localtime:ro

networks:
  tsingyun:
    external: true
```

## 启动容器

```bash
cd /home/application/Database/clickhouse
docker-compose up -d
docker-compose ps
```

## 验证

```bash
docker exec -it clickhouse clickhouse-client --password 'YOUR_CLICKHOUSE_PASSWORD' -q 'SELECT version()'
```

升级前备份数据目录。
