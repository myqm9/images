#!/bin/bash
set -euo pipefail

# 定义镜像名称和版本号
IMAGE_NAME_1="apollo-configservice"
IMAGE_NAME_2="apollo-adminservice"
IMAGE_NAME_3="apollo-portal"
IMAGE_VERSION="2.3.0"

# 检查镜像名称和版本号是否设置
if [ -z "${IMAGE_NAME_1:-}" ] || [ -z "${IMAGE_NAME_2:-}" ] || [ -z "${IMAGE_NAME_3:-}" ] || [ -z "${IMAGE_VERSION:-}" ]; then
    echo "❌ 错误：必须定义镜像名称和版本号 " >&2
    exit 1
fi

# 打印初始信息用于调试
for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
    echo "🔨 正在构建 Docker 镜像: ${i}:${IMAGE_VERSION}"
done

# Docker 构建命令
for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
    cd /workspace/Middleware/apollo/$i && docker build --pull --no-cache \
    -t "$i:${IMAGE_VERSION}" \
    --build-arg "$i=${i}" \
    --build-arg "IMAGE_VERSION=${IMAGE_VERSION}" . \
    || { 
        echo "❌ 错误：镜像构建失败" >&2
        echo "apollo 镜像构建失败" >> /tmp/CUSTOM_ENV_RESULT_INFO
        exit 1
    } \
done

echo "✅ 镜像构建成功"
# 标记为 CNB 镜像
for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
docker tag \
    "$i:${IMAGE_VERSION}" \
    "${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/$i:${IMAGE_VERSION}" \
    || { echo "❌ 错误：镜像标记失败（CNB）" >&2; exit 1; } \
done

echo "✅ 镜像标记至 CNB 仓库成功"

# 标记为腾讯云 TCR 镜像
for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
docker tag \
    "$i:${IMAGE_VERSION}" \
    "${TencentCloud_REGISTRY}/${REGISTRY_ORG}/$i:${IMAGE_VERSION}" \
    || { echo "❌ 错误：镜像标记失败（腾讯云 TCR）" >&2; exit 1; } \
done

echo "✅ 镜像标记至腾讯云 TCR 仓库成功"





# 推送至 CNB 仓库
echo "🔨 正在推送镜像到 CNB 仓库..."

for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
skopeo copy --insecure-policy docker-daemon:${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/$i:${IMAGE_VERSION} docker://${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}/$i:${IMAGE_VERSION} \
    || { echo "❌ 错误：CNB 镜像推送失败" >&2; exit 1; } \
done

echo "✅ CNB 镜像推送成功"



# 推送至腾讯云 TCR 仓库
echo "🔨 正在推送镜像到腾讯云 TCR 仓库..."

for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
skopeo copy --insecure-policy docker-daemon:${TencentCloud_REGISTRY}/${REGISTRY_ORG}/$i:${IMAGE_VERSION} docker://${TencentCloud_REGISTRY}/${REGISTRY_ORG}/$i:${IMAGE_VERSION} \
    || { echo "❌ 错误：腾讯云 TCR 镜像推送失败" >&2; exit 1; } \
done

echo "✅ 腾讯云 TCR 镜像推送成功"



# 输出镜像地址到文件（确保目录存在）
output_dir="/tmp"
if [ ! -d "$output_dir" ]; then
    echo "❌ 错误：输出目录 ${output_dir} 不存在" >&2
    exit 1
fi

for i in ${IMAGE_NAME_1} ${IMAGE_NAME_2} ${IMAGE_NAME_3}; do
echo "${TencentCloud_REGISTRY}/${REGISTRY_ORG}/$i:${IMAGE_VERSION}" >> "${output_dir}/CUSTOM_ENV_RESULT_INFO"
done

echo "✅ 镜像地址已写入 ${output_dir}/CUSTOM_ENV_RESULT_INFO"