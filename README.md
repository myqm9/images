# **中间件**
| **软件**     | **版本**                        | **镜像说明** | **镜像地址**                                                 | **端口**          | **说明**                                         |
| ------------ | ------------------------------- | ------------ | ------------------------------------------------------------ | ----------------- | ------------------------------------------------ |
| clickhouse   | 24.5.1                          | AMD64        | harbor.tsingyun.net/tsingyun-middleware/clickhouse:24.5.1    | 8123 9000         |  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/clickhouse:23.3.9.55-arm64 |                   | 鲲鹏920上实测这个版本可用  |
| influxdb     | 2.9.1                         | AMD64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:2.9.1       | 8086              | 带 UI 界面                                       |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:2.9.1-arm64 |                   |                                                  |
|              | 3.9.0                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:3.9.0       | 8181              | 不带 UI 界面，空库创建                           |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:3.9.0-arm64 |                   |                                                  |
| Influxdb3-ui | 1.6.3                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:influxdb3-ui-1.6.3 | 3100              | nginx代理了一层Influxdb3-ui                      |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/influxdb:influxdb3-ui-1.6.3-arm64 |                   |  |
| postgres     | 15.18-alpine3.24                | AMD64        | harbor.tsingyun.net/tsingyun-middleware/postgres:15.18-alpine3.24 | 5432              |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/postgres:15.18-alpine3.24-arm64 |                   |                                                  |
| postgis      | 15.18-3.5.7                     | AMD64        | harbor.tsingyun.net/tsingyun-middleware/postgis:15.18-3.5.7  | 5432              | pgrouting3.7.1                                   |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/postgis:15.18-3.5.7-arm64 |                   |                                                  |
| redis        | 8.10.1                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/redis:8.10.1          | 6379              |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/redis:8.10.1-arm64    |                   |                                                  |
| apollo       | 2.3.0                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/apollo-portal:2.3.0 harbor.tsingyun.net/tsingyun-middleware/apollo-configservice:2.3.0 harbor.tsingyun.net/tsingyun-middleware/apollo-adminservice:2.3.0 | 10002 10003 10004 |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/apollo-portal:2.3.0-arm64 harbor.tsingyun.net/tsingyun-middleware/apollo-configservice:2.3.0-arm64 harbor.tsingyun.net/tsingyun-middleware/apollo-adminservice:2.3.0-arm64 |                   |                                                  |
| emqx         | 4.3                            | AMD64        | harbor.tsingyun.net/tsingyun-middleware/emqx:4.3            | 18083 1883        | 老版本，不推荐使用          |
|              | 5.8.9                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/emqx:5.8.9           | 18083 1883        | 可免费使用的单节点版本，之后版本不在开源 |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/emqx:5.8.9-arm64     |                   |                                                  |
| fastdfs      | 6.10.0                          | AMD64        | harbor.tsingyun.net/tsingyun-middleware/fastdfs:6.10.0       | 22122 23000       |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/fastdfs:6.10.0-arm64 |                   |                                                  |
| kafka        | 3.9.2                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/kafka-kraft:3.9.2    | 9092              |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/kafka-kraft:3.9.2-arm64 |                   |                                                  |
| kafka-map    | 1.3.3                           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/kafka-map:1.3.3      | 8080              |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/kafka-map:1.3.3-arm64 |                   |                                                  |
| minio        | RELEASE.2025-10-15T17-29-55Z    | AMD64        | harbor.tsingyun.net/tsingyun-middleware/minio:RELEASE.2025-10-15T17-29-55Z | 9000 9001         |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/minio:RELEASE.2025-10-15T17-29-55Z-arm64 |                   |                                                  |
| geoserver    | geoserver=2.27.1 tomcat:9.0.105 | AMD64        | harbor.tsingyun.net/tsingyun-middleware/geoserver:2.27.1     | 8080              |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/geoserver:2.27.1-arm64 |                   |                                                  |
| nacos        | 2.5.3                          | AMD64        | harbor.tsingyun.net/tsingyun-middleware/tsingyun-nacos:2.5.3 | 8848 9848         |                                        |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/tsingyun-nacos:2.5.3-arm64 |                   |                                                  |
| openjdk      | v11_0_23-jdk-ubi9-x86           | AMD64        | harbor.tsingyun.net/tsingyun-middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-x86 |                   |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-arm64 |                   |                                                  |
| libreoffice | openjdk11-7.5       | AMD64        | harbor.tsingyun.net/tsingyun-middleware/libreoffice:openjdk11-7.5 |                   |                                       |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/libreoffice:openjdk11-7.5-arm64 |                   |                                                  |
| nginx        | 1.28.3                          | AMD64        | harbor.tsingyun.net/tsingyun-middleware/nginx:1.28.3         |                   |                                                  |
|              |                                 | ARM64        | harbor.tsingyun.net/tsingyun-middleware/nginx:1.28.3-arm64   |                   |                                                  |
| mongo        | mongo:latest                    | 官方镜像     | mongo:latest                                                 | 27017             |                                                  |
| mysql        | 5.7.44                   | 官方镜像     | mysql:5.7.44                                    | 3306              |                                                  |
|  | 8.0.38 | 官方镜像 | mysql:8.0.38 | 3306 | |


## 镜像版本管理

自建中间件的版本、基础镜像、源码校验和以及架构标签在 [versions.env](versions.env) 中维护。构建脚本使用 Bash 读取清单，Dockerfile 中带 `# versions.env:` 注释的 `ARG` 默认值由清单同步，支持原来的 `docker build` 用法。

升级时，修改组件所在段的版本，并更新与发行包配套的校验和。然后在仓库根目录执行：

```bash
bash scripts/sync-versions.sh --write
bash scripts/sync-versions.sh --check
bash Middleware/redis/build.sh --local
```

`--write` 更新 Dockerfile 默认值，提交时请一起提交清单和生成的差异。`--check` 检查全仓库。CNB 构建时检查所选组件和架构的 Dockerfile，发现差异会显示参数名、当前值和清单值。

| 构建场景 | 示例 |
| --- | --- |
| 本地构建 AMD64 镜像 | `bash Middleware/redis/build.sh --local` |
| 在 ARM64 节点构建历史版本 | `bash Middleware/redis/8.2.2/build-arm64.sh --local` |
| CNB 构建并推送到两个仓库 | 在已配置仓库凭据的 CI 中运行原有的 `bash build.sh` 或 `bash build-arm64.sh` |

在对应架构的节点上运行构建，跨架构执行 Dockerfile 的 `RUN` 步骤需要构建器支持模拟。Apollo 入口会依次构建 configservice、adminservice、portal 三个镜像。ClickHouse 的 AMD64 软件包版本保留四段，镜像标签保留前三段，ARM64 单独选用兼容版本。LibreOffice 保留历史标签 `openjdk11-7.5` 和兼容目录，实际安装的 Alpine 软件包由 `LIBREOFFICE_APK_VERSION` 指定。MySQL 等直接引用官方镜像的部署示例继续在各自部署文件中配置。

# deploy 说明

## docker-compose 说明
