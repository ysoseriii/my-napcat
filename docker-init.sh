#!/bin/bash
# init: volume 合并脚本 — 先将预置数据迁到 /data，再启动官方 entrypoint

set -e

mkdir -p /data/config /data/QQ

# 首次运行：把镜像里预置的 config 迁到 volume
if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

# 替换为软链接
rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config

mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

exec bash /app/entrypoint.sh "$@"
