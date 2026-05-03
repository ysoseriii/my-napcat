#!/bin/bash
# init: volume merge + OneBot HTTP API + 定时调度 + 测试消息
set -e

ACCOUNT="${ACCOUNT:-3059754914}"

mkdir -p /data/config /data/QQ

# 首次运行：迁预置 config 到 volume
if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

# 软链接
rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config
mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

# 注入 OneBot HTTP API 配置（localhost:3000，免鉴权）
cp /scripts/onebot-http.json "/data/config/onebot11_${ACCOUNT}.json"

# 启动后台定时调度器
bash /scripts/daily-scheduler.sh &
echo "[init] 定时调度器已启动 (PID $!)"

# 延迟发送测试消息（等 QQ 登录，~90s）
(
    sleep 90
    TARGET_QQ=1308357113 /scripts/send-msg.sh "此条为测试消息
道爷我成啦"
) &

exec bash /app/entrypoint.sh "$@"
