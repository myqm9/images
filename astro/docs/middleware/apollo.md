---
title: Apollo
sidebar: { order: 6 }
---

Apollo 由 Config Service、Admin Service 和 Portal 三个服务组成，依赖 MySQL。当前纳管镜像为 2.3.0。园区与企业使用不同的初始化 SQL（大小写敏感策略不同），compose 结构相同。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

| 服务 | AMD64 | ARM64 |
| --- | --- | --- |
| Portal | `{{ images.amd64.portal.reference }}` | `{{ images.arm64.portal.reference }}` |
| Config Service | `{{ images.amd64.configservice.reference }}` | `{{ images.arm64.configservice.reference }}` |
| Admin Service | `{{ images.amd64.adminservice.reference }}` | `{{ images.arm64.adminservice.reference }}` |

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- MySQL 可访问。创建 `ApolloConfigDB`、`ApolloPortalDB`，并执行对应版本的初始化 SQL。
- ARM64 主机请将下方三个 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Middleware/apollo/logs
```

## 初始化数据库

按项目类型下载初始化 SQL【见交付物清单】：

- 园区（大小写敏感）：[apollo-2.3-yq-大小写敏感-new.sql](https://file.tsingyun.link/docker/Database/mysql/docker-compose/apollo-2.3-yq-%E5%A4%A7%E5%B0%8F%E5%86%99%E6%95%8F%E6%84%9F-new.sql)
- 企业（忽略大小写）：[apollo-2.3-qy-忽略大小写-new.sql](https://file.tsingyun.link/docker/Database/mysql/docker-compose/apollo-2.3-qy-%E5%BF%BD%E7%95%A5%E5%A4%A7%E5%B0%8F%E5%86%99-new.sql)

企业项目要求 MySQL `my.cnf` 含 `lower_case_table_names=1`。

导入后修改：

1. `ApolloConfigDB.ServerConfig` 中的 `eureka.service.url`，例如 `http://YOUR_SERVER_IP:10002/eureka/`
2. `ApolloPortalDB.ServerConfig` 中的 `apollo.portal.envs`，例如 `baseline`

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/apollo/docker-compose.yml`。`APOLLO_PORTAL_ENVS` 与 `*_META` 前缀必须一致，例如环境名 `baseline` 对应 `baseline_META`。

```yaml
services:
  apollo-configservice:
    container_name: apollo-configservice
    image: {{ images.amd64.configservice.reference }}
    volumes:
      - /home/application/Middleware/apollo/logs:/opt/logs
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "10002:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://YOUR_MYSQL_HOST:3306/ApolloConfigDB?characterEncoding=utf8
      - SPRING_DATASOURCE_USERNAME=YOUR_APOLLO_DB_USER
      - SPRING_DATASOURCE_PASSWORD=YOUR_APOLLO_DB_PASSWORD
      - EUREKA_INSTANCE_HOME_PAGE_URL=http://YOUR_SERVER_IP:10002
      - EUREKA_INSTANCE_IP_ADDRESS=YOUR_SERVER_IP
      - TZ=Asia/Shanghai
    restart: always
    networks:
      - tsingyun

  apollo-adminservice:
    depends_on:
      - apollo-configservice
    container_name: apollo-adminservice
    image: {{ images.amd64.adminservice.reference }}
    volumes:
      - /home/application/Middleware/apollo/logs:/opt/logs
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "10003:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://YOUR_MYSQL_HOST:3306/ApolloConfigDB?characterEncoding=utf8
      - SPRING_DATASOURCE_USERNAME=YOUR_APOLLO_DB_USER
      - SPRING_DATASOURCE_PASSWORD=YOUR_APOLLO_DB_PASSWORD
      - EUREKA_INSTANCE_HOME_PAGE_URL=http://YOUR_SERVER_IP:10003
      - EUREKA_INSTANCE_IP_ADDRESS=YOUR_SERVER_IP
      - TZ=Asia/Shanghai
    restart: always
    networks:
      - tsingyun

  apollo-portal:
    depends_on:
      - apollo-adminservice
    container_name: apollo-portal
    image: {{ images.amd64.portal.reference }}
    volumes:
      - /home/application/Middleware/apollo/logs:/opt/logs
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "10004:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://YOUR_MYSQL_HOST:3306/ApolloPortalDB?characterEncoding=utf8
      - SPRING_DATASOURCE_USERNAME=YOUR_APOLLO_DB_USER
      - SPRING_DATASOURCE_PASSWORD=YOUR_APOLLO_DB_PASSWORD
      - APOLLO_PORTAL_ENVS=baseline
      - baseline_META=http://YOUR_SERVER_IP:10002
      - TZ=Asia/Shanghai
    restart: always
    networks:
      - tsingyun

networks:
  tsingyun:
    external: true
```

企业项目库名也可能是全小写 `apolloconfigdb` / `apolloportaldb`，以初始化 SQL 为准。

## 启动容器

```bash
cd /home/application/Middleware/apollo
docker-compose up -d
docker-compose ps
```

预期三个服务均为 `running`：Config `10002`、Admin `10003`、Portal `10004`。

## 验证

- Eureka / Config：`http://YOUR_SERVER_IP:10002`
- Portal：`http://YOUR_SERVER_IP:10004`
- 默认用户名 / 密码：`apollo` / `YOUR_APOLLO_PORTAL_PASSWORD`（以初始化 SQL 为准，登录后立即修改）

确认服务注册、命名空间创建与配置发布可用。升级前备份 `ApolloConfigDB` 与 `ApolloPortalDB`。
