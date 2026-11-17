---
title: MinIO
sidebar: { order: 10 }
---

采用 docker-compose 容器编排方式部署。MinIO 提供 S3 兼容对象存储，包含 API 端口 `9000` 和控制台端口 `9001`。`minio-init` 会自动创建 `tsingyun` 桶；ACCESSKEY 非必须，业务可用 root 账号联调，需要独立密钥时再创建。

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
mkdir -p /home/application/Middleware/minio/{data,mc-config}
```

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/minio/docker-compose.yml`。`minio-init` 会在 MinIO 就绪后创建初始 bucket。

```yaml
services:
  minio:
    image: {{ image.amd64.reference }}
    container_name: minio
    networks:
      - tsingyun
    ports:
      - 9000:9000
      - 9001:9001
    volumes:
      - /home/application/Middleware/minio/data:/data
      - /home/application/Middleware/minio/mc-config:/tmp/.mc:rw
      - /etc/localtime:/etc/localtime:ro
      - /usr/share/zoneinfo:/usr/share/zoneinfo:ro
    environment:
      MINIO_ROOT_USER: YOUR_MINIO_ROOT_USER
      MINIO_ROOT_PASSWORD: YOUR_MINIO_ROOT_PASSWORD
      TZ: Asia/Shanghai
    command: server /data --console-address :9001
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 10
    restart: unless-stopped

  minio-init:
    image: {{ image.amd64.reference }}
    container_name: minio-init
    depends_on:
      minio:
        condition: service_healthy
    networks:
      - tsingyun
    volumes:
      - /home/application/Middleware/minio/mc-config:/tmp/.mc:rw
    entrypoint: >
      /bin/sh -c "
      /usr/bin/mc alias set minio http://minio:9000 YOUR_MINIO_ROOT_USER 'YOUR_MINIO_ROOT_PASSWORD';
      /usr/bin/mc mb minio/tsingyun;
      /usr/bin/mc ls minio;
      exit 0;
      "

networks:
  tsingyun:
    external: true
```

## 启动容器

```bash
cd /home/application/Middleware/minio
docker-compose up -d
docker-compose ps
```

`minio` 应为 `running (healthy)`，`minio-init` 执行完成后退出码为 `0`。

## 创建业务访问密钥

在线密钥生成工具：https://motools.net/zh/dev/secret-key-generator

```bash
docker exec -it minio bash
mc admin user add minio YOUR_ACCESS_KEY YOUR_SECRET_KEY
mc admin policy attach minio readwrite --user YOUR_ACCESS_KEY
exit
```

控制台对象浏览器可查看 bucket 与上传结果：

![MinIO 对象浏览器](/images/middleware/minio/object-browser.png)

使用 S3 客户端完成 bucket、上传和下载测试。数据目录必须纳入备份。
