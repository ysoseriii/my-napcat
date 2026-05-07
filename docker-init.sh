#!/bin/bash
# 按需模式 v3：前台 entrypoint，后台发消息，SIGTERM 优雅退出
set -e

EMOJI_DICT='🔥 🌿 💧 😋'
TARGET_QQ="${TARGET_QQ:-1308357113}"
MAIN_PID=$$

mkdir -p /data/config /data/QQ

if [ ! -f /data/config/napcat.json ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
fi

rm -rf /app/napcat/config
ln -sfn /data/config /app/napcat/config
mkdir -p /app/.config
rm -rf /app/.config/QQ
ln -sfn /data/QQ /app/.config/QQ

if [ "${TEST_MODE:-0}" = "1" ]; then
    WAIT=10
else
    WAIT=$(( RANDOM % 7380 ))
    JITTER=$(( (RANDOM % 7) - 3 ))
    [ $JITTER -eq 0 ] && JITTER=1
    WAIT=$((WAIT + JITTER * 60))
    [ $WAIT -lt 10 ] && WAIT=10
fi

echo "[init] ${WAIT}秒后发送，启动 NapCat..."

(
    for i in $(seq 1 72); do
        sleep 5
        python3 -c "import socket;s=socket.socket();s.settimeout(2);s.connect(('127.0.0.1',3001));s.close();print('OK')" 2>/dev/null | grep -q OK && break
    done

    sleep "$WAIT"

    read -ra ITEMS <<< "$EMOJI_DICT"
    EMOJI="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
    echo "[send] $EMOJI -> $TARGET_QQ"
    TARGET_QQ="$TARGET_QQ" /app/scripts/send-msg.sh "$EMOJI"

    sleep 30
    echo "[send] 关机"
    kill -TERM $MAIN_PID 2>/dev/null || true
    sleep 10
    kill -9 $MAIN_PID 2>/dev/null || true
) &

trap 'echo "[init] 收到信号，退出"; exit 0' SIGTERM
bash /app/entrypoint.sh "$@"
