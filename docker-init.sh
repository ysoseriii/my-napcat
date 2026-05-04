#!/bin/bash
# 按需模式：启动 NapCat → 等 WS 就绪 → 随机延时 → 发消息 → 退出
set -e

EMOJI_DICT='🔥 🌿 💧 😋'
TARGET_QQ="${TARGET_QQ:-1308357113}"

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

# 等 WebSocket 就绪（最多 5 分钟）
echo "[init] 等待 QQ 上线..."
for i in $(seq 1 60); do
    sleep 5
    python3 -c "
import socket
s=socket.socket();s.settimeout(2)
try:
 s.connect(('127.0.0.1',3001));s.close();print('OK')
except: pass
" 2>/dev/null | grep -q OK && { echo "[init] WS 就绪 (${i}x5s)"; break; }
    echo "[init] 等待... ($i/60)"
done

# 随机延时：5-185 分钟窗口（6:00 ~ 9:00 UTC+8）
OFFSET=$((300 + RANDOM % 10800 ))
JITTER=$(( (RANDOM % 7) - 3 ))
[ $JITTER -eq 0 ] && JITTER=1
OFFSET=$((OFFSET + JITTER * 60))
[ $OFFSET -lt 60 ] && OFFSET=60

echo "[init] ${OFFSET}秒后发送..."
sleep "$OFFSET"

# 随机 emoji
read -ra ITEMS <<< "$EMOJI_DICT"
EMOJI="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
echo "[init] 发送: $EMOJI → $TARGET_QQ"
TARGET_QQ="$TARGET_QQ" /app/scripts/send-msg.sh "$EMOJI"

echo "[init] 完成，30秒后关机"
sleep 30
kill $NAPCAT_PID 2>/dev/null || true
exit 0
