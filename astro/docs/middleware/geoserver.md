---
title: GeoServer
sidebar: { order: 11 }
---

采用 docker-compose 容器编排方式部署。当前镜像为 GeoServer 2.27.1，基于 Tomcat 9.0.105。需持久化数据目录，并挂载地图数据。

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
mkdir -p /home/application/Middleware/geoserver
```

地图数据后续放到 `/home/application/Middleware/geoserver/map-data`。

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/geoserver/docker-compose.yml`：

```yaml
services:
  geoserver:
    container_name: geoserver
    image: {{ image.amd64.reference }}
    networks:
      - tsingyun
    ports:
      - "8080:8080"
    environment:
      - GEOSERVER_ADMIN_USER=admin
      - GEOSERVER_ADMIN_PASSWORD=YOUR_GEOSERVER_PASSWORD
      - SKIP_DEMO_DATA=true
      - CORS_ENABLED=true
      - TZ=Asia/Shanghai
      - EXTRA_JAVA_OPTS=-Xms1G -Xmx2G
    volumes:
      - /home/application/Middleware/geoserver/data:/opt/geoserver_data/
      - /home/application/Middleware/geoserver/map-data:/map
    restart: always

networks:
  tsingyun:
    external: true
```

## 启动容器

```bash
cd /home/application/Middleware/geoserver
docker-compose up -d
docker-compose ps
```

预期输出类似：

```text
NAME                COMMAND                  SERVICE             STATUS              PORTS
geoserver           "bash /opt/startup.sh"   geoserver           running (healthy)   0.0.0.0:8080->8080/tcp
```

## 测试：先建图层

准备测试栅格文件 [rxn.tif](https://file.tsingyun.link/linux-soft/geoserver/rxn.tif)，下载到 `/home/application/Middleware/geoserver/map-data`。确认目录中已有该文件：

![确认 rxn.tif 已放到 map-data](/images/middleware/geoserver/map-data.png)

访问 `http://YOUR_SERVER_IP:8080/geoserver`，使用管理员账号登录。首次登录后修改默认密码。

### 新建工作空间

![新建工作空间](/images/middleware/geoserver/workspace.png)

### 新建存储仓库

![新建存储仓库](/images/middleware/geoserver/store.png)

选择栅格数据源类型：

![选择栅格数据存储](/images/middleware/geoserver/store-raster.png)

### 添加栅格数据源

连接 URL 指向容器内地图目录，例如 `/map/rxn.tif`。

![添加栅格数据源](/images/middleware/geoserver/add-coverage.png)

### 发布图层

![发布图层](/images/middleware/geoserver/publish.png)

确认坐标系与边界后保存：

![图层发布参数](/images/middleware/geoserver/layer.png)

用 Layer Preview 打开测试图层，确认影像可预览：

![图层预览](/images/middleware/geoserver/layer-preview.png)

备份 `data` 目录、地图原始数据与样式文件。
