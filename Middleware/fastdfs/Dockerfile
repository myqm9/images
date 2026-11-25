# versions.env: FASTDFS_BASE_IMAGE
ARG FASTDFS_BASE_IMAGE=mirror.ccs.tencentyun.com/library/alpine
FROM ${FASTDFS_BASE_IMAGE}

# 设置环境变量
# versions.env: LIBFASTCOMMON_VERSION
ARG LIBFASTCOMMON_VERSION=V1.0.70
# versions.env: LIBSERVERFRAME_VERSION
ARG LIBSERVERFRAME_VERSION=V1.2.0
# versions.env: FASTDFS_VERSION
ARG FASTDFS_VERSION=V6.10.0
ENV INSTALL_PATH=/usr/local/src \
    FASTDFS_BASE_PATH=/home/dfs/data \
    LIBFASTCOMMON_VERSION="${LIBFASTCOMMON_VERSION}" \
    LIBSERVERFRAME_VERSION="${LIBSERVERFRAME_VERSION}" \
    FASTDFS_VERSION="${FASTDFS_VERSION}" \
    TZ=Asia/Shanghai

# 更改系统源以便安装库
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.nju.edu.cn/g' /etc/apk/repositories
RUN sed -i 's@dl-cdn.alpinelinux.org@mirrors.cloud.tencent.com@g' /etc/apk/repositories


# 初始化、安装依赖、编译安装包并清理
RUN mkdir -p ${INSTALL_PATH} \
 && apk update && apk add --no-cache --virtual .build-deps \
    bash git autoconf gcc libc-dev make pcre-dev zlib-dev linux-headers gnupg libxslt-dev gd-dev geoip-dev wget \
 && apk add --no-cache bash pcre-dev zlib-dev tzdata \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && cd ${INSTALL_PATH} \
 && git clone -b $LIBFASTCOMMON_VERSION https://gitee.com/fastdfs100/libfastcommon.git libfastcommon \
 && cd ${INSTALL_PATH}/libfastcommon/ \
 && ./make.sh && ./make.sh install \
 && cd ${INSTALL_PATH} \
 && git clone -b $LIBSERVERFRAME_VERSION https://gitee.com/fastdfs100/libserverframe.git libserverframe \
 && cd ${INSTALL_PATH}/libserverframe/ \
 && ./make.sh && ./make.sh install \
 && cd ${INSTALL_PATH} \
 && git clone -b $FASTDFS_VERSION https://gitee.com/fastdfs100/fastdfs.git fastdfs \
 && cd ${INSTALL_PATH}/fastdfs/ \
 && ./make.sh && ./make.sh install \
 && rm -rf ${INSTALL_PATH}/* \
 && apk del .build-deps \
 && rm -rf /var/cache/apk/*

# 添加配置文件和启动脚本
COPY conf/*.* /etc/fdfs/
COPY start.sh /

# 更改启动脚本执行权限
RUN chmod u+x /start.sh

# 暴露端口
EXPOSE 22122 23000

# 设置工作目录
WORKDIR /

# 镜像启动
ENTRYPOINT ["/bin/bash", "/start.sh"]
