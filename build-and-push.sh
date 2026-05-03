#!/bin/bash
# ============================================
# NapCat Linux Docker — 构建 & 推送
# 用法: DOCKERHUB_USER=yourname ./build-and-push.sh
# ============================================
set -euo pipefail

DOCKERHUB_USER="${DOCKERHUB_USER:-}"
if [ -z "$DOCKERHUB_USER" ]; then
    echo ">>> 请设置 DOCKERHUB_USER 变量"
    echo "    DOCKERHUB_USER=myusername ./build-and-push.sh"
    exit 1
fi

IMAGE_NAME="${DOCKERHUB_USER}/napcat:latest"

echo ">>> 构建镜像: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

echo ">>> 推送镜像"
docker push "$IMAGE_NAME"

echo ">>> 完成! 镜像: docker.io/$IMAGE_NAME"
echo ""
echo ">>> 运行测试:"
echo "    docker run -d --name napcat -p 6099:6099 $IMAGE_NAME"
echo ">>> 查看令牌:"
echo "    docker logs napcat"
echo ""
echo ">>> 各平台部署时，直接拉取你的镜像: docker.io/$IMAGE_NAME"
