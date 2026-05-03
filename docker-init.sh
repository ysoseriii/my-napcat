#!/bin/bash
# Lagrange.OneBot 启动脚本
set -e

# 首次运行：复制模板配置到持久化 volume
if [ ! -f /app/data/appsettings.json ]; then
    cp /app/templates/appsettings.json /app/data/appsettings.json
    echo "[init] 首次运行，已写入配置文件"
fi

# 确保 config 在正确位置（每次从 volume 读）
# Lagrange 从 WORKDIR 读 appsettings.json

echo "[init] 启动 Lagrange.OneBot (Watch 协议)..."

# 启动 Lagrange（前台阻塞，日志包含二维码）
# 用 script 创建伪终端（.NET 需要终端环境才能初始化 Console）
script -qfc "/app/bin/Lagrange.OneBot" /dev/null &

LAGRANGE_PID=$!
echo "[init] Lagrange PID: $LAGRANGE_PID"

# 启动定时调度器
bash /app/scripts/daily-scheduler.sh &
echo "[init] 调度器 PID: $!"

# 等 QQ 登录后发测试消息
(
    sleep 120
    TARGET_QQ=1308357113 /app/scripts/send-msg.sh "此条为测试消息
道爷我成啦"
) &

# 等待 Lagrange 主进程
wait $LAGRANGE_PID
