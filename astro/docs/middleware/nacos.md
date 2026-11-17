---
title: Nacos
sidebar: { order: 12 }
---

采用 docker-compose 容器编排方式部署。Nacos 用于服务注册、配置管理和服务发现，提供两种存储方式：

- **MySQL**：外置数据库，支持多节点共享数据，适合生产环境。
- **Derby**：内嵌数据库，单机使用，部署简单，不支持集群。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 方式一：MySQL 持久化

生产环境使用此方式。当前镜像依赖 MySQL 8。

### 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- MySQL 实例可访问。

### 创建工作目录

```bash
mkdir -p /home/application/Middleware/nacos/
```

### 初始化数据库

登录数据库，创建库和用户。密码插件需指定 `mysql_native_password`：

```sql
CREATE DATABASE nacos CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER nacos@'%' IDENTIFIED WITH mysql_native_password BY 'YOUR_NACOS_DB_PASSWORD';
GRANT ALL ON nacos.* TO nacos@'%';

-- 业务 JDBC 账号按项目需要创建，不要与 Nacos 元数据库账号混用
CREATE USER YOUR_JDBC_USER@'%' IDENTIFIED BY 'YOUR_JDBC_PASSWORD';
GRANT ALL ON *.* TO YOUR_JDBC_USER@'%';
```

登录数据库，用 [mysql-schema.sql](https://file.tsingyun.link/docker/Middleware/nacos/2.5.3/mysql-schema.sql) 初始化 `nacos` 库【见交付物清单】。完整脚本如下：

```sql
USE nacos;

CREATE TABLE `config_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) DEFAULT NULL,
  `content` longtext NOT NULL COMMENT 'content',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(50) DEFAULT NULL COMMENT 'source ip',
  `app_name` varchar(128) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  `c_desc` varchar(256) DEFAULT NULL,
  `c_use` varchar(64) DEFAULT NULL,
  `effect` varchar(64) DEFAULT NULL,
  `type` varchar(64) DEFAULT NULL,
  `c_schema` text,
  `encrypted_data_key` text NOT NULL COMMENT '秘钥',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfo_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info';

CREATE TABLE `config_info_aggr` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `datum_id` varchar(255) NOT NULL COMMENT 'datum_id',
  `content` longtext NOT NULL COMMENT '内容',
  `gmt_modified` datetime NOT NULL COMMENT '修改时间',
  `app_name` varchar(128) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfoaggr_datagrouptenantdatum` (`data_id`,`group_id`,`tenant_id`,`datum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='增加租户字段';

CREATE TABLE `config_info_beta` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL COMMENT 'content',
  `beta_ips` varchar(1024) DEFAULT NULL COMMENT 'betaIps',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(50) DEFAULT NULL COMMENT 'source ip',
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  `encrypted_data_key` text NOT NULL COMMENT '秘钥',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfobeta_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_beta';

CREATE TABLE `config_info_tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
  `tag_id` varchar(128) NOT NULL COMMENT 'tag_id',
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL COMMENT 'content',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(50) DEFAULT NULL COMMENT 'source ip',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfotag_datagrouptenanttag` (`data_id`,`group_id`,`tenant_id`,`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_tag';

CREATE TABLE `config_tags_relation` (
  `id` bigint(20) NOT NULL COMMENT 'id',
  `tag_name` varchar(128) NOT NULL COMMENT 'tag_name',
  `tag_type` varchar(64) DEFAULT NULL COMMENT 'tag_type',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
  `nid` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`nid`),
  UNIQUE KEY `uk_configtagrelation_configidtag` (`id`,`tag_name`,`tag_type`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_tag_relation';

CREATE TABLE `group_capacity` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Group ID，空字符表示整个集群',
  `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '配额，0表示使用默认值',
  `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '使用量',
  `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置大小上限，单位为字节，0表示使用默认值',
  `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '聚合子配置最大个数，0表示使用默认值',
  `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个聚合数据的子配置大小上限，单位为字节，0表示使用默认值',
  `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最大变更历史数量',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='集群、各Group容量信息表';

CREATE TABLE `his_config_info` (
  `id` bigint(20) unsigned NOT NULL,
  `nid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `data_id` varchar(255) NOT NULL,
  `group_id` varchar(128) NOT NULL,
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL,
  `md5` varchar(32) DEFAULT NULL,
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `src_user` text,
  `src_ip` varchar(50) DEFAULT NULL,
  `op_type` char(10) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  `encrypted_data_key` text NOT NULL COMMENT '秘钥',
  PRIMARY KEY (`nid`),
  KEY `idx_gmt_create` (`gmt_create`),
  KEY `idx_gmt_modified` (`gmt_modified`),
  KEY `idx_did` (`data_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='多租户改造';

CREATE TABLE `tenant_capacity` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tenant_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Tenant ID',
  `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '配额，0表示使用默认值',
  `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '使用量',
  `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置大小上限，单位为字节，0表示使用默认值',
  `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '聚合子配置最大个数',
  `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个聚合数据的子配置大小上限，单位为字节，0表示使用默认值',
  `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最大变更历史数量',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='租户容量信息表';

CREATE TABLE `tenant_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `kp` varchar(128) NOT NULL COMMENT 'kp',
  `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
  `tenant_name` varchar(128) DEFAULT '' COMMENT 'tenant_name',
  `tenant_desc` varchar(256) DEFAULT NULL COMMENT 'tenant_desc',
  `create_source` varchar(32) DEFAULT NULL COMMENT 'create_source',
  `gmt_create` bigint(20) NOT NULL COMMENT '创建时间',
  `gmt_modified` bigint(20) NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_info_kptenantid` (`kp`,`tenant_id`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='tenant_info';

CREATE TABLE `users` (
  `username` varchar(50) NOT NULL PRIMARY KEY,
  `password` varchar(500) NOT NULL,
  `enabled` boolean NOT NULL
);

CREATE TABLE `roles` (
  `username` varchar(50) NOT NULL,
  `role` varchar(50) NOT NULL,
  UNIQUE INDEX `idx_user_role` (`username` ASC, `role` ASC) USING BTREE
);

CREATE TABLE `permissions` (
  `role` varchar(50) NOT NULL,
  `resource` varchar(255) NOT NULL,
  `action` varchar(8) NOT NULL,
  UNIQUE INDEX `uk_role_permission` (`role`,`resource`,`action`) USING BTREE
);

INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', TRUE);
INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN');
```

### 编写 docker-compose.yml

需要配置 Nacos 连接 MySQL 的账户信息，并开启鉴权。`NACOS_AUTH_TOKEN`、`NACOS_AUTH_IDENTITY_VALUE` 需自行生成随机串，不要使用示例值上线。

* 在线密钥生成工具：https://motools.net/zh/dev/secret-key-generator

编辑 `/home/application/Middleware/nacos/docker-compose.yml`：

```yaml
services:
  nacos:
    image: {{ image.amd64.reference }}
    container_name: nacos
    networks:
      - tsingyun
    restart: always
    ports:
      - 8848:8848
      - 9848:9848
    environment:
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=YOUR_MYSQL_HOST
      - MYSQL_SERVICE_PORT=3306
      - MYSQL_SERVICE_DB_NAME=nacos
      - MYSQL_SERVICE_USER=nacos
      - MYSQL_SERVICE_PASSWORD=YOUR_NACOS_DB_PASSWORD
      - MYSQL_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&allowPublicKeyRetrieval=true&autoReconnect=true&serverTimezone=Asia/Shanghai
      - NACOS_AUTH_ENABLE=true
      - NACOS_AUTH_TOKEN=YOUR_NACOS_AUTH_TOKEN
      - NACOS_AUTH_IDENTITY_KEY=serverIdentity
      - NACOS_AUTH_IDENTITY_VALUE=YOUR_NACOS_IDENTITY_VALUE
    volumes:
      - ./logs:/home/nacos/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8848/nacos/actuator/health"]
      interval: 30s
      retries: 3
      start_period: 10s
      timeout: 10s

networks:
  tsingyun:
    external: true
```

### 启动容器

```bash
cd /home/application/Middleware/nacos
docker-compose up -d
docker-compose ps
```

预期输出类似：

```text
NAME                COMMAND                  SERVICE             STATUS              PORTS
nacos               "sh bin/docker-start…"   nacos               running (healthy)   0.0.0.0:8848->8848/tcp, 0.0.0.0:9848->9848/tcp
```

### 登录控制台并修改密码

- 登录地址：`http://YOUR_SERVER_IP:8848/nacos`
- 默认用户名 / 密码：`nacos` / `nacos`

内部系统，不可暴露到公网。

![Nacos 登录页](/images/middleware/nacos/login.png)

首次登录后立即修改控制台密码：

![在权限控制中打开修改密码](/images/middleware/nacos/change-password-menu.png)

![重置 Nacos 控制台密码](/images/middleware/nacos/reset-password.png)

### 配置客户端鉴权

开启鉴权后，微服务注册与拉配置需在 JVM 参数中指定控制台账号：

```text
-Dspring.cloud.nacos.config.username=nacos
-Dspring.cloud.nacos.config.password=YOUR_NACOS_CONSOLE_PASSWORD
-Dspring.cloud.nacos.discovery.username=nacos
-Dspring.cloud.nacos.discovery.password=YOUR_NACOS_CONSOLE_PASSWORD
```

升级前备份 Nacos 数据库与日志。

## 方式二：Derby 内嵌库

仅适合单机试验，不支持集群。

### 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。

### 创建工作目录

```bash
mkdir -p /home/application/Middleware/nacos/
```

### 编写 docker-compose.yml

需要开启鉴权 `NACOS_AUTH_TOKEN`、`NACOS_AUTH_IDENTITY_VALUE` 需自行生成随机串，不要使用示例值上线。

* 在线密钥生成工具：https://motools.net/zh/dev/secret-key-generator

```yaml
services:
  nacos:
    image: {{ image.amd64.reference }}
    container_name: nacos
    networks:
      - tsingyun
    restart: always
    ports:
      - 8848:8848
      - 9848:9848
    environment:
      - MODE=standalone
      - NACOS_AUTH_ENABLE=true
      - NACOS_AUTH_TOKEN=YOUR_NACOS_AUTH_TOKEN
      - NACOS_AUTH_IDENTITY_KEY=serverIdentity
      - NACOS_AUTH_IDENTITY_VALUE=YOUR_NACOS_IDENTITY_VALUE
    volumes:
      - ./logs:/home/nacos/logs
      - ./data:/home/nacos/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8848/nacos/actuator/health"]
      interval: 30s
      retries: 3
      start_period: 10s
      timeout: 10s

networks:
  tsingyun:
    external: true
```

### 启动容器

```bash
cd /home/application/Middleware/nacos
docker-compose up -d
docker-compose ps
```

预期输出类似：

```text
NAME                COMMAND                  SERVICE             STATUS              PORTS
nacos               "sh bin/docker-start…"   nacos               running (healthy)   0.0.0.0:8848->8848/tcp, 0.0.0.0:9848->9848/tcp
```

### 登录控制台并修改密码

- 登录地址：`http://YOUR_SERVER_IP:8848/nacos`
- 默认用户名 / 密码：`nacos` / `nacos`

![在权限控制中打开修改密码](/images/middleware/nacos/change-password-menu.png)

![重置 Nacos 控制台密码](/images/middleware/nacos/reset-password.png)

### 配置客户端鉴权

```text
-Dspring.cloud.nacos.config.username=nacos
-Dspring.cloud.nacos.config.password=YOUR_NACOS_CONSOLE_PASSWORD
-Dspring.cloud.nacos.discovery.username=nacos
-Dspring.cloud.nacos.discovery.password=YOUR_NACOS_CONSOLE_PASSWORD
```

Derby 数据在 `./data` 目录，升级或迁移前一并备份日志与数据目录。
