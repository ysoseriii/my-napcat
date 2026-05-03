#!/bin/bash
# 后台调度器：每日 UTC+8 随机时段发送 emoji
# 不使用 cron，纯 shell 循环

EMOJI_DICT='🔥 🌿 💧 😋'
TARGET_QQ="${TARGET_QQ:-1308357113}"
SEND_SCRIPT="/scripts/send-msg.sh"
LOG_FILE="/data/daily-send.log"

while true; do
    # 随机选 UTC+8 的小时 (6/7/8) + 分钟 + ±1~3min 偏移
    HOURS=(6 7 8)
    HOUR=${HOURS[$((RANDOM % 3))]}
    OFFSET=$(( (RANDOM % 7) - 3 ))
    [ $OFFSET -eq 0 ] && OFFSET=$(( (RANDOM % 2) * 2 - 1 ))
    MINUTE=$(( (RANDOM % 60) + OFFSET ))
    [ $MINUTE -lt 0 ] && { MINUTE=$((MINUTE+60)); HOUR=$((HOUR-1)); [ $HOUR -lt 0 ] && HOUR=23; }
    [ $MINUTE -ge 60 ] && { MINUTE=$((MINUTE-60)); HOUR=$((HOUR+1)); [ $HOUR -ge 24 ] && HOUR=0; }

    # 获取当前时间（UTC秒）
    NOW_UTC=$(date -u +%s)

    # 计算今天目标时间的 UTC 秒
    # UTC+8 HOUR:MINUTE → UTC (HOUR-8):MINUTE
    UTC_HOUR=$(( (HOUR - 8 + 24) % 24 ))
    TARGET_DATE=$(date -u -d "@$NOW_UTC" +%Y-%m-%d)
    TARGET_UTC_SEC=$(date -u -d "${TARGET_DATE} ${UTC_HOUR}:${MINUTE}:00" +%s 2>/dev/null)

    # 如果今天的目标时间已过，等明天
    if [ "$TARGET_UTC_SEC" -le "$NOW_UTC" ]; then
        TARGET_UTC_SEC=$(date -u -d "${TARGET_DATE} ${UTC_HOUR}:${MINUTE}:00 +1 day" +%s 2>/dev/null)
    fi

    SLEEP_SEC=$(( TARGET_UTC_SEC - NOW_UTC ))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 下次发送: $(date -u -d "@$TARGET_UTC_SEC" '+%Y-%m-%d %H:%M:%S UTC') (等待 ${SLEEP_SEC}s)" | tee -a "$LOG_FILE"

    sleep "$SLEEP_SEC"

    # 发送随机 emoji
    read -ra ITEMS <<< "$EMOJI_DICT"
    EMOJI="${ITEMS[$((RANDOM % ${#ITEMS[@]}))]}"
    TARGET_QQ="$TARGET_QQ" "$SEND_SCRIPT" "$EMOJI" >> "$LOG_FILE" 2>&1

    # 短暂休息后进入下一天
    sleep 10
done
