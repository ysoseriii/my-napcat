#!/bin/bash
# 首次登录模式：直接跑官方 entrypoint，保持在线直到手动停止

mkdir -p /data/config /data/QQ

if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config
mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

echo "[init] 登录模式：启动 NapCat，WebUI 在端口 6099"
exec bash /app/entrypoint.sh "$@"
