---
title: Kafka
sidebar: { order: 9 }
---

采用 docker-compose 容器编排方式部署。当前镜像为 Kafka KRaft `3.9.2`，无需 ZooKeeper。单节点适用于开发、测试或已评估可用性风险的场景。部署前必须配置对外公布的监听地址。可选附带 `kafka-map` Web 管理台。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

`kafka-map` 镜像：

- AMD64：`harbor.tsingyun.net/tsingyun-middleware/kafka-map:1.3.3`
- ARM64：`harbor.tsingyun.net/tsingyun-middleware/kafka-map:1.3.3-arm64`

## 前提条件

- 已完成 [Docker 与 Compose](/prerequisites/docker/) 安装，并已创建 `tsingyun` 自定义网络。
- ARM64 主机请将下方 compose 中的 `image` 换成发布信息中的 ARM64 镜像。

## 创建工作目录

```bash
mkdir -p /home/application/Middleware/kafka/{data,logs,kafka-map/data}
```

## 编写 docker-compose.yml

编辑 `/home/application/Middleware/kafka/docker-compose.yml`。将 `YOUR_SERVER_IP` 换成 Kafka 对外可达的主机地址；`kafka-map` 默认密码必须改成自己的密钥。

```yaml
services:
  kafka:
    image: {{ image.amd64.reference }}
    container_name: kafka
    environment:
      # KAFKA_LISTENERS: PLAINTEXT://:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://YOUR_SERVER_IP:9092
      # KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      # KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      TZ: Asia/Shanghai
    ports:
      - "9092:9092"
    volumes:
      - /home/application/Middleware/kafka/logs:/opt/kafka/logs
      - /home/application/Middleware/kafka/data:/tmp/kraft-combined-logs
    restart: always
    healthcheck:
      test: ["CMD", "nc", "-z", "127.0.0.1", "9092"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - tsingyun

  kafka-map:
    image: harbor.tsingyun.net/tsingyun-middleware/kafka-map:1.3.3
    container_name: kafka-map
    networks:
      - tsingyun
    volumes:
      - /home/application/Middleware/kafka/kafka-map/data:/usr/local/kafka-map/data
    ports:
      - 19006:8080
    environment:
      DEFAULT_USERNAME: admin
      DEFAULT_PASSWORD: YOUR_KAFKA_MAP_PASSWORD
    depends_on:
      - kafka
    restart: unless-stopped

networks:
  tsingyun:
    external: true
```

不需要管理台时，可删除 `kafka-map` 服务。

## 启动容器

```bash
cd /home/application/Middleware/kafka
docker-compose up -d
docker-compose ps
```

## 使用 kafka-map

[kafka-map](https://github.com/dushixiang/kafka-map/blob/master/README-zh_CN.md) 是 Web 管理工具，用于查看集群、主题与消费组。

浏览器打开 `http://YOUR_SERVER_IP:19006`，使用 compose 中的 `DEFAULT_USERNAME` / `DEFAULT_PASSWORD` 登录。

![kafka-map 登录](/images/middleware/kafka/kafka-map-login.png)

登录后点击接入集群，名称自定义，集群地址填写 `YOUR_SERVER_IP:9092`，确认保存。

![接入 Kafka 集群](/images/middleware/kafka/kafka-map-cluster.png)

接入成功后，集群列表会出现 Broker、主题与消费组入口。

![集群列表](/images/middleware/kafka/kafka-map-overview.png)

修改监听地址或数据目录前应评估数据兼容性。
