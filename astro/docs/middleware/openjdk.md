---
title: OpenJDK
sidebar: { order: 13 }
---

该组件是 Java 业务镜像的运行环境。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 使用方式

在业务 Dockerfile 中引用：

```dockerfile
FROM {{ image.amd64.reference }}

 # 工作目录
WORKDIR /opt/app
# jvm
ENV JAVA_OPTS=""

# 拷贝文件
COPY ./target/*.jar app.jar
# 设置端口 配置中心会覆盖
#EXPOSE 7011

CMD java -jar -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Duser.timezone=GMT+8 ${JAVA_OPTS} app.jar

```

ARM64 构建请改用发布信息中的 ARM64 镜像。