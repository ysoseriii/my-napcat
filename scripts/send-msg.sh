#!/bin/bash
# NapCat OneBot HTTP API — 发送私聊消息
set -e

API_HOST="${API_HOST:-127.0.0.1:3000}"
TARGET_QQ="${TARGET_QQ:-1308357113}"
TOKEN="${NAPCAT_TOKEN:-}"

MESSAGE="${1:-}"

# 当参数是空格分隔的 emoji 列表时，随机选一个
if echo "$MESSAGE" | grep -qE '[🔥🌿💧😋]'; then
    read -ra ITEMS <<< "$MESSAGE"
    MESSAGE="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
fi

if [ -z "$MESSAGE" ]; then
    echo "用法: $0 \"消息或emoji列表\""
    exit 1
fi

AUTH_HDR=""
[ -n "$TOKEN" ] && AUTH_HDR="Authorization: Bearer ${TOKEN}"

for i in $(seq 1 30); do
    if [ -n "$TOKEN" ]; then
        RESP=$(curl -s --max-time 5 \
            "http://${API_HOST}/send_private_msg" \
            -H "Content-Type: application/json" \
            -H "$AUTH_HDR" \
            -d "{\"user_id\":${TARGET_QQ},\"message\":\"${MESSAGE}\"}")
    else
        RESP=$(curl -s --max-time 5 \
            "http://${API_HOST}/send_private_msg" \
            -H "Content-Type: application/json" \
            -d "{\"user_id\":${TARGET_QQ},\"message\":\"${MESSAGE}\"}")
    fi

    if echo "$RESP" | grep -qE '"status":"ok"|"retcode":0'; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 发送成功: $MESSAGE → QQ $TARGET_QQ"
        exit 0
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 重试 $i/30: $RESP"
    sleep 10
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 发送失败"
exit 1
