# versions.env: OPENJDK_IMAGE_AMD64
ARG OPENJDK_IMAGE_AMD64=dockerhub.qingcloud.com/tsingyun_middleware/tsingyun-openjdk:v11_0_23-jdk-ubi9-x86
FROM ${OPENJDK_IMAGE_AMD64}

# 定义apollo-adminservice-VERSION版本
# versions.env: APOLLO_VERSION
ARG VERSION=2.3.0

ENV APOLLO_RUN_MODE "Docker"
ENV SERVER_PORT 8080

# 安装必要的工具
RUN dnf update -y && \
    # 安装必要的工具
    dnf install -y bash curl unzip wget && \
    mkdir /apollo-adminservice && \
    # 设置时区
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    # 创建 locale 配置文件
    echo "LANG=zh_CN.UTF-8" > /etc/locale.conf && \
    echo "LC_TIME=zh_CN.UTF-8" >> /etc/locale.conf && \
    # 清理缓存
    dnf clean all && \
    rm -rf /var/cache/dnf


# 下载并安装 apollo-adminservice
RUN set -x \
    && wget "https://cnb.cool/tsingyun/devops/tsingyun-images-oss/-/releases/download/v1.0.0/apollo-adminservice-${VERSION}-github.zip" \
    && unzip apollo-adminservice-${VERSION}-github.zip -d apollo-adminservice \
    && mv apollo-adminservice/apollo-adminservice-${VERSION}.jar /apollo-adminservice \
    && rm -rf apollo-adminservice-${VERSION}-github.zip apollo-adminservice
    
#复制启动脚本到容器
COPY ./scripts /apollo-adminservice/scripts

EXPOSE $SERVER_PORT

# 确保脚本具有执行权限
RUN chmod +x /apollo-adminservice/scripts/*.sh

# 设置容器的默认启动命令
CMD ["/apollo-adminservice/scripts/startup.sh"]

