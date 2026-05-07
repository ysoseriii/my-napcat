#!/bin/bash
# 按需模式 v2：前台跑 entrypoint，后台发消息，发送后自毁
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

# 测试模式：只等 10 秒
if [ "${TEST_MODE:-0}" = "1" ]; then
    WAIT=10
else
    # 随机延时: 0-123 分钟 (对应 6:00~8:03 UTC+8)
    WAIT=$(( RANDOM % 7380 ))
    JITTER=$(( (RANDOM % 7) - 3 ))
    [ $JITTER -eq 0 ] && JITTER=1
    WAIT=$((WAIT + JITTER * 60))
    [ $WAIT -lt 10 ] && WAIT=10
fi

echo "[init] ${WAIT}秒后发送，启动 NapCat..."

# 后台：等 QQ 就绪 → 延时 → 发消息 → 杀进程
(
    # 等 QQ 完全就绪（最多 6 分钟）
    for i in $(seq 1 72); do
        sleep 5
        python3 -c "import socket;s=socket.socket();s.settimeout(2);s.connect(('127.0.0.1',3001));s.close();print('OK')" 2>/dev/null | grep -q OK && break
    done

    sleep "$WAIT"

    read -ra ITEMS <<< "$EMOJI_DICT"
    EMOJI="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
    echo "[send] $EMOJI → $TARGET_QQ"
    TARGET_QQ="$TARGET_QQ" /app/scripts/send-msg.sh "$EMOJI"

    sleep 30
    echo "[send] 关机"
    # 杀掉所有 QQ 进程 → entrypoint 退出 → 机器停止
    pkill -9 qq 2>/dev/null || true
    sleep 5
    # 兜底：如果机器还在，杀 entrypoint
    pkill -9 entrypoint 2>/dev/null || true
) &

# 前台：官方 entrypoint
exec bash /app/entrypoint.sh "$@"
