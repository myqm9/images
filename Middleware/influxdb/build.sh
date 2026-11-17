#!/bin/bash
set -euo pipefail

# 定义镜像名称和版本号
IMAGE_NAME="influxdb"
IMAGE_VERSION="3.9.0"

# 检查镜像名称和版本号是否设置
if [ -z "${IMAGE_NAME:-}" ] || [ -z "${IMAGE_VERSION:-}" ]; then
    echo "❌ 错误：必须定义镜像名称和版本号 " >&2
    exit 1
fi

# 打印初始信息用于调试
echo "🔨  开始构建 Docker 镜像: ${IMAGE_NAME}:${IMAGE_VERSION}"

# Docker 构建命令
docker build --pull --no-cache \
    -t "dockerhub.qingcloud.com/tsingyun_middleware/${IMAGE_NAME}:${IMAGE_VERSION}" \
    --build-arg "IMAGE_NAME=${IMAGE_NAME}" \
    --build-arg "IMAGE_VERSION=${IMAGE_VERSION}" . \
    || { 
        echo "❌ 错误：镜像构建失败" >&2
        echo "${IMAGE_NAME} 镜像构建失败" >> /tmp/CUSTOM_ENV_RESULT_INFO
        exit 1
    }

echo "✅ 镜像构建成功"

# 标记为 CNB 镜像
docker tag \
    "dockerhub.qingcloud.com/tsingyun_middleware/${IMAGE_NAME}:${IMAGE_VERSION}" \
    "${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/${IMAGE_NAME}:${IMAGE_VERSION}" \
    || { echo "❌ 错误：镜像标记失败（CNB）" >&2; exit 1; }

echo "✅ 镜像标记至 CNB 仓库成功"

# 标记为 tsingyun-harbor 镜像
docker tag \
    "dockerhub.qingcloud.com/tsingyun_middleware/${IMAGE_NAME}:${IMAGE_VERSION}" \
    "harbor.tsingyun.net/tsingyun-middleware/${IMAGE_NAME}:${IMAGE_VERSION}" \
    || { echo "❌ 错误：镜像标记失败（CNB）" >&2; exit 1; }

echo "✅ 镜像标记至 tsingyun-harbor 仓库成功"

# 推送至qingcloud仓库
echo "🔨 正在推送镜像到qingcloud仓库..."
skopeo copy  --insecure-policy docker-daemon:dockerhub.qingcloud.com/tsingyun_middleware/${IMAGE_NAME}:${IMAGE_VERSION} docker://dockerhub.qingcloud.com/tsingyun_middleware/${IMAGE_NAME}:${IMAGE_VERSION} \
    || { echo "❌ 错误：qingcloud镜像推送失败" >&2; exit 1; }

echo "✅ qingcloud镜像推送成功"


# 推送至 CNB 仓库
echo "🔨 正在推送镜像到 CNB 仓库..."
skopeo copy --insecure-policy docker-daemon:${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/${IMAGE_NAME}:${IMAGE_VERSION} docker://${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/${IMAGE_NAME}:${IMAGE_VERSION} \
    || { echo "❌ 错误：CNB 镜像推送失败" >&2; exit 1; }

echo "✅ CNB 镜像推送成功"


# 推送至 tsingyun-harbor 仓库
echo "🔨 正在推送镜像到 tsingyun-harbor  仓库..."
skopeo copy --insecure-policy docker-daemon:harbor.tsingyun.net/tsingyun-middleware/${IMAGE_NAME}:${IMAGE_VERSION} docker://harbor.tsingyun.net/tsingyun-middleware/${IMAGE_NAME}:${IMAGE_VERSION} \
    || { echo "❌ 错误：tsingyun-harbor 镜像推送失败" >&2; exit 1; }

echo "✅ tsingyun-harbor  镜像推送成功"

# 输出镜像地址到文件（确保目录存在）
output_dir="/tmp"
if [ ! -d "$output_dir" ]; then
    echo "❌ 错误：输出目录 ${output_dir} 不存在" >&2
    exit 1
fi

echo "harbor.tsingyun.net/tsingyun-middleware/${IMAGE_NAME}:${IMAGE_VERSION}" >> "${output_dir}/CUSTOM_ENV_RESULT_INFO" \
    || { echo "❌ 错误：无法写入镜像信息文件" >&2; exit 1; }

echo "✅ 镜像地址已写入 ${output_dir}/CUSTOM_ENV_RESULT_INFO"