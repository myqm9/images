---
title: LibreOffice
sidebar: { order: 14 }
---

该镜像提供基于 OpenJDK 的 LibreOffice 运行环境。

:::caution
初始化用户名、密码、组织和 Token 写在 compose 的环境变量中，**生产环境必须改成自己的密钥**，不要使用文档中的占位符。
:::

## 发布信息

- AMD64 镜像：`{{ image.amd64.reference }}`
- ARM64 镜像：`{{ image.arm64.reference }}`

## 使用方式
```dockerfile
# jdk
FROM {{ image.amd64.reference }}

 # 工作目录
WORKDIR /opt/app
# jvm
ENV JAVA_OPTS=""

# 拷贝文件
COPY ./target/*.jar app.jar

RUN apk add --no-cache libreoffice && ln -sf /usr/lib/libreoffice /opt/libreoffice7.5

CMD java -jar -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Duser.timezone=GMT+8 ${JAVA_OPTS} app.jar

```
