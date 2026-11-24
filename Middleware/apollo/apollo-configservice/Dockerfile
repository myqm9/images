# versions.env: OPENJDK_IMAGE_AMD64
ARG OPENJDK_IMAGE_AMD64=dockerhub.qingcloud.com/tsingyun_middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-x86
FROM ${OPENJDK_IMAGE_AMD64}

# 定义apollo-configservice-VERSION版本
# versions.env: APOLLO_VERSION
ARG VERSION=2.3.0

ENV APOLLO_RUN_MODE "Docker"
ENV SERVER_PORT 8080

# 安装必要的工具
RUN dnf update -y && \
    # 安装必要的工具
    dnf install -y bash curl unzip wget && \
    mkdir /apollo-configservice && \
    # 设置时区
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    # 创建 locale 配置文件
    echo "LANG=zh_CN.UTF-8" > /etc/locale.conf && \
    echo "LC_TIME=zh_CN.UTF-8" >> /etc/locale.conf && \
    # 清理缓存
    dnf clean all && \
    rm -rf /var/cache/dnf

# 下载并安装 apollo-configservice
RUN set -x \
    && wget "https://cnb.cool/myqm/images-oss/-/releases/download/v1.0.0/apollo-configservice-${VERSION}-github.zip" \
    && unzip apollo-configservice-${VERSION}-github.zip -d apollo-configservice \
    && mv apollo-configservice/apollo-configservice-${VERSION}.jar /apollo-configservice \
    && rm -rf apollo-configservice-${VERSION}-github.zip apollo-configservice

#复制启动脚本到容器
COPY ./scripts /apollo-configservice/scripts

EXPOSE $SERVER_PORT

# 确保脚本具有执行权限
RUN chmod +x /apollo-configservice/scripts/*.sh

# 设置容器的默认启动命令
CMD ["/apollo-configservice/scripts/startup.sh"]
