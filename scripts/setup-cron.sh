#!/bin/bash
# 设置每日定时：UTC+8 随机 6:00-8:59，±1-3min 偏移 → 发送随机 emoji
set -e

EMOJI_DICT='🔥 🌿 💧 😋'
TARGET_QQ="${TARGET_QQ:-1308357113}"
CRON_SCRIPT="/scripts/send-msg.sh"
LOG_FILE="/data/cron-daily.log"

# 随机选小时：6, 7, 8
HOURS=(6 7 8)
HOUR=${HOURS[$((RANDOM % 3))]}

# 随机偏移 ±1~3 min（禁止 0）
OFFSET=$(( (RANDOM % 7) - 3 ))
[ $OFFSET -eq 0 ] && OFFSET=$(( (RANDOM % 2) * 2 - 1 ))

MINUTE=$(( (RANDOM % 60) + OFFSET ))
if [ $MINUTE -lt 0 ]; then MINUTE=$((MINUTE+60)); HOUR=$((HOUR-1)); [ $HOUR -lt 0 ] && HOUR=23; fi
if [ $MINUTE -ge 60 ]; then MINUTE=$((MINUTE-60)); HOUR=$((HOUR+1)); [ $HOUR -ge 24 ] && HOUR=0; fi

# UTC+8 → UTC
UTC_HOUR=$(( (HOUR - 8 + 24) % 24 ))

# 清旧任务 + 加新任务
crontab -l 2>/dev/null | grep -v "$CRON_SCRIPT" | crontab - 2>/dev/null || true
(crontab -l 2>/dev/null; echo "$MINUTE $UTC_HOUR * * * $CRON_SCRIPT '$EMOJI_DICT' >> $LOG_FILE 2>&1") | crontab -

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 定时已设置: UTC+8 ${HOUR}:${MINUTE} (UTC ${UTC_HOUR}:${MINUTE})"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 目标 QQ: $TARGET_QQ"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ emoji: $EMOJI_DICT"
