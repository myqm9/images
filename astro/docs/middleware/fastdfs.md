---
title: FastDFS
sidebar: { order: 8 }
---

采用 docker-compose 容器编排方式部署。当前镜像使用宿主机网络模式，部署前必须确认宿主机 IP 以及 Tracker / Storage 端口规划。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Middleware/fastdfs/fastdfs_data
```

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/fastdfs/docker-compose.yml`。FastDFS 走宿主机网络，将 `YOUR_SERVER_IP` 换成宿主机业务 IP。

```yaml
services:
  fastdfs:
    image: {{ image.amd64.reference }}
    container_name: fastdfs
    restart: always
    volumes:
      - /home/application/Middleware/fastdfs/fastdfs_data:/home/dfs/data
      - /etc/localtime:/etc/localtime:ro
    environment:
      FASTDFS_IPADDR: YOUR_SERVER_IP
      TZ: Asia/Shanghai
    network_mode: host
```

使用 `network_mode: host` 时不要再配置 `ports` 或加入 `tsingyun` bridge 网络。

## 启动容器

```bash
cd /home/application/Middleware/fastdfs
docker-compose up -d
docker-compose ps
```

## 验证

确认日志无 Tracker / Storage 注册错误，并完成上传、下载测试。数据目录必须纳入备份。
