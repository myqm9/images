# 使用 Alpine Linux 作为基础镜像
FROM alpine:latest

# 维护者信息
LABEL maintainer="srebro"
LABEL description="Custom Skopeo image based on Alpine Linux"

# 更换为腾讯云镜像源并更新系统
RUN sed -i 's@dl-cdn.alpinelinux.org@mirrors.cloud.tencent.com@g' /etc/apk/repositories \
    && apk update \
    && apk upgrade

# 安装必要的依赖包
RUN apk add --no-cache \
    skopeo \
    ca-certificates \
    tzdata \
    bash \
    curl \
    git \
    wget \
    unzip \
    openssh-server \
    jq


# 设置时区为上海
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 创建工作目录
WORKDIR /app

# 创建基本的 policy.json 文件以避免 skopeo 策略错误
RUN mkdir -p /etc/containers && \
    echo '{"default":[{"type":"insecureAcceptAnything"}]}' > /etc/containers/policy.json

# 指定字符集支持命令行输入中文（根据需要选择字符集）
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8

# 验证 skopeo 安装
RUN skopeo --version

# 默认命令
CMD ["/bin/bash"]