# 使用基于 OpenJDK 11 的 JDK镜像
# versions.env: TEMURIN_BASE_IMAGE
ARG TEMURIN_BASE_IMAGE
FROM ${TEMURIN_BASE_IMAGE}

# 先安装基础工具
RUN microdnf update -y && \
    microdnf install -y \
        dnf && \
    microdnf clean all

# 设置环境变量
ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# 安装必需软件包 (使用dnf替代microdnf以获得更好的依赖解决)
RUN dnf update -y && \
    dnf install -y --allowerasing \
        tzdata \
        fontconfig \
        curl \
        bash \
        unzip \
        tar \
        nc \
        wget \
        vim && \
    # 设置时区
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    # 创建 locale 配置文件
    echo "LANG=zh_CN.UTF-8" > /etc/locale.conf && \
    echo "LC_TIME=zh_CN.UTF-8" >> /etc/locale.conf && \
    # 清理缓存
    dnf clean all && \
    rm -rf /var/cache/dnf

# 创建字体目录
RUN mkdir -p /usr/share/fonts/chinese

# 复制自定义字体 (如果存在)
COPY ./fonts/ /usr/share/fonts/chinese/
RUN chmod 644 /usr/share/fonts/chinese/*; \
    fc-cache -f -v;

# 最终清理
RUN rm -rf /tmp/* /var/tmp/* /var/log/*

# 工作目录
WORKDIR /app

# 默认命令 (示例)
CMD ["bash", "-lc", "echo 容器已启动，当前时间为 $(date '+%F %T %Z'); tail -f /dev/null"]
