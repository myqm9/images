ARG VERSION=11-alpine3.19-jdk
FROM amazoncorretto:${VERSION}

# 替换默认的软件源为腾讯云镜像源,更新系统并安装软件包
RUN sed -i 's@dl-cdn.alpinelinux.org@mirrors.cloud.tencent.com@g' /etc/apk/repositories && \
    sed -i '/https:\/\/apk\.corretto\.aws/d' /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache curl vim libreoffice && \
    ln -sf /usr/lib/libreoffice /opt/libreoffice7.5 && \
    rm -rf /var/cache/apk/*


# 下载并解压字体文件
RUN set -x \
    && wget "https://cnb.cool/tsingyun/devops/tsingyun-images-oss/-/releases/download/v1.0.0/fonts.tar.gz" \
    && tar -xf fonts.tar.gz -C /usr/share/ \
    && rm -rf fonts.tar.gz

