#!/bin/bash
# 按需模式：启动 → 等 QQ 登录 → 随机延时 → 发消息 → 退出
set -e

ACCOUNT="${ACCOUNT:-1215207734}"
TARGET_QQ="${TARGET_QQ:-1308357113}"
EMOJI_DICT='🔥 🌿 💧 😋'

mkdir -p /data/config /data/QQ

if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config
mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

echo "[init] 启动 NapCat..."
bash /app/entrypoint.sh &
NAPCAT_PID=$!

# 等待 QQ 登录（轮询 WebSocket 端口）
echo "[init] 等待 QQ 登录..."
for i in $(seq 1 60); do
    sleep 5
    # 检测 WebSocket 端口是否就绪
    if python3 -c "
import socket
s = socket.socket()
s.settimeout(2)
try:
    s.connect(('127.0.0.1', 3001))
    s.close()
    print('OK')
except:
    pass
" 2>/dev/null | grep -q OK; then
        echo "[init] NapCat WebSocket 已就绪 (${i}x5s)"
        break
    fi
    echo "[init] 等待中... ($i/60)"
done

# 随机延时：在 6:00-8:59 UTC+8 窗口内
# 机器在 5:55 左右启动，偏移 5-185 分钟
OFFSET_MIN=5
OFFSET_MAX=185
OFFSET=$((OFFSET_MIN + RANDOM % (OFFSET_MAX - OFFSET_MIN + 1)))
# ±1-3 分钟抖动
JITTER=$(( (RANDOM % 7) - 3 ))
[ $JITTER -eq 0 ] && JITTER=1
OFFSET=$((OFFSET + JITTER))
[ $OFFSET -lt 1 ] && OFFSET=1

echo "[init] 延时 ${OFFSET} 秒后发送..."
sleep "$OFFSET"

# 随机 emoji
read -ra ITEMS <<< "$EMOJI_DICT"
EMOJI="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"

echo "[init] 发送: $EMOJI → QQ $TARGET_QQ"
TARGET_QQ="$TARGET_QQ" /app/scripts/send-msg.sh "$EMOJI"

echo "[init] 完成，60 秒后退出"
sleep 60

kill $NAPCAT_PID 2>/dev/null || true
exit 0
