#!/bin/bash
# 通过 NapCat WebSocket (端口 3001) 发送私聊消息
set -e

TARGET_QQ="${TARGET_QQ:-1308357113}"
WS_PORT="${WS_PORT:-3001}"
MESSAGE="${1:-}"

# emoji 列表 → 随机选
if echo "$MESSAGE" | grep -qE '[🔥🌿💧😋]'; then
    read -ra ITEMS <<< "$MESSAGE"
    MESSAGE="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
fi

[ -z "$MESSAGE" ] && { echo "用法: $0 消息"; exit 1; }

for i in $(seq 1 30); do
    RESP=$(python3 -c "
import asyncio, json

async def send():
    try:
        r, w = await asyncio.wait_for(
            asyncio.open_connection('127.0.0.1', $WS_PORT), timeout=5)
        payload = json.dumps({
            'action': 'send_private_msg',
            'params': {
                'user_id': $TARGET_QQ,
                'message': '$MESSAGE'
            }
        })
        w.write(payload.encode() + b'\n')
        await w.drain()
        data = await asyncio.wait_for(r.read(8192), timeout=5)
        w.close()
        return json.loads(data)
    except Exception as e:
        return {'error': str(e)}

print(json.dumps(asyncio.run(send()), ensure_ascii=False))
" 2>&1)

    echo "[$(date '+%H:%M:%S')] 尝试 $i/30: $RESP"

    if echo "$RESP" | grep -qE '"status":"ok"|"retcode":0'; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 发送成功: $MESSAGE → QQ $TARGET_QQ"
        exit 0
    fi

    sleep 10
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 发送失败"
exit 1
