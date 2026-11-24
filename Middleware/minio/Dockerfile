# 阶段1：依赖下载层
# versions.env: MINIO_BUILDER_IMAGE
ARG MINIO_BUILDER_IMAGE=golang:1.24.11-alpine3.23
# versions.env: MINIO_BASE_IMAGE
ARG MINIO_BASE_IMAGE=minio/minio:latest
FROM ${MINIO_BUILDER_IMAGE} AS builder

# 定义MINIO版本
# versions.env: MINIO_VERSION
ARG MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z

WORKDIR /app

# 下载minio并构建二进制
RUN wget https://cnb.cool/tsingyun/devops/tsingyun-images-oss/-/releases/download/v1.0.0/minio-${MINIO_VERSION}.tar.gz \
&& tar -zxvf minio-${MINIO_VERSION}.tar.gz \
&& rm -rf minio-${MINIO_VERSION}.tar.gz \
&& cd minio-${MINIO_VERSION} \
&& go mod tidy \
&& go build



# 阶段3：生成最终镜像
#官方的 minio 镜像自带了 mc 命令
FROM ${MINIO_BASE_IMAGE}

# 定义MINIO版本
# versions.env: MINIO_VERSION
ARG MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z

COPY --from=builder /app/minio-${MINIO_VERSION}/minio /usr/bin/minio
COPY --from=builder /app/minio-${MINIO_VERSION}/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

RUN chmod -R 777 /usr/bin && chmod +x /usr/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
VOLUME ["/data"]
CMD ["minio"]
