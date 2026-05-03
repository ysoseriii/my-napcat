#!/bin/bash
# init: volume merge + 定时调度 + 测试消息
set -e

mkdir -p /data/config /data/QQ

# 首次运行：迁预置 config 到 volume
if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

# 清理旧 onebot 配置，让 MODE 模板生效
rm -f /data/config/onebot11_*.json

# 软链接
rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config
mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

# 启动后台定时调度器
bash /scripts/daily-scheduler.sh &
echo "[init] 调度器已启动 (PID $!)"

# 延迟发送测试消息（等 QQ 登录，~120s）
(
    sleep 120
    TARGET_QQ=1308357113 /scripts/send-msg.sh "此条为测试消息
道爷我成啦"
) &

exec bash /app/entrypoint.sh "$@"
