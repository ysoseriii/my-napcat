#!/bin/bash
# Lagrange.OneBot 启动脚本

# 首次运行：复制模板配置到持久化 volume
if [ ! -f /app/data/appsettings.json ]; then
    cp /app/templates/appsettings.json /app/data/appsettings.json
    echo "[init] 首次运行，已写入配置文件"
fi

echo "[init] 启动 Lagrange.OneBot (Watch 协议)..."

# 启动定时调度器
bash /app/scripts/daily-scheduler.sh &
echo "[init] 调度器 PID: $!"

# 等 QQ 登录后发测试消息（只发一次）
FIRST_RUN_FLAG="/app/data/.test_msg_sent"
(
    sleep 120
    if [ ! -f "$FIRST_RUN_FLAG" ]; then
        TARGET_QQ=1308357113 /app/scripts/send-msg.sh "此条为测试消息
道爷我成啦"
        touch "$FIRST_RUN_FLAG"
    fi
) &

# 循环重启 Lagrange（崩溃时自动重拉）
while true; do
    echo "[init] 启动 Lagrange (PID $$)..."
    script -qfc "/app/bin/Lagrange.OneBot" /dev/null
    echo "[init] Lagrange 退出(退出码 $?)，5秒后重启..."
    sleep 5
done
