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


# deploy 说明

## docker-compose 说明
