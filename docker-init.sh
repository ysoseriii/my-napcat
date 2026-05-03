#!/bin/bash
# init: volume merge + OneBot HTTP setup + cron + test message
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

# 设置每日定时
/scripts/setup-cron.sh

# 启动 cron
cron

# 延迟发送测试消息（等 QQ 登录完，~90s）
(
    sleep 90
    TARGET_QQ=1308357113 /scripts/send-msg.sh "此条为测试消息
道爷我成啦"
) &

exec bash /app/entrypoint.sh "$@"
