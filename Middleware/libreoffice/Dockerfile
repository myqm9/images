# versions.env: CORRETTO_11_TAG
ARG VERSION=11-alpine3.19-jdk
FROM amazoncorretto:${VERSION}
# versions.env: LIBREOFFICE_SERIES
ARG LIBREOFFICE_SERIES=7.5
# versions.env: LIBREOFFICE_APK_VERSION
ARG LIBREOFFICE_APK_VERSION=7.6.7.2

# 替换默认的软件源为腾讯云镜像源,更新系统并安装软件包
RUN sed -i 's@dl-cdn.alpinelinux.org@mirrors.cloud.tencent.com@g' /etc/apk/repositories && \
    sed -i '/https:\/\/apk\.corretto\.aws/d' /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache curl vim "libreoffice~${LIBREOFFICE_APK_VERSION}" && \
    ln -sf /usr/lib/libreoffice /opt/libreoffice${LIBREOFFICE_SERIES} && \
    rm -rf /var/cache/apk/*


# 下载并解压字体文件
RUN set -x \
    && wget "https://cnb.cool/myqm/images-oss/-/releases/download/v1.0.0/fonts.tar.gz" \
    && tar -xf fonts.tar.gz -C /usr/share/ \
    && rm -rf fonts.tar.gz

