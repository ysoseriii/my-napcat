#!/bin/bash
# wrapper: 处理 volume 合并 + 避免首轮 unzip 冲突

mkdir -p /data/config /data/QQ

# 等待官方 entrypoint 完成初始化（unzip 等），再接管目录
bash /app/entrypoint.sh "$@" &
EPID=$!

# 给 entrypoint 最多 30 秒完成 unzip
for i in $(seq 1 30); do
    if [ -f /app/napcat/napcat.mjs ]; then
        break
    fi
    sleep 1
done

# 将真实目录迁移到 volume 上，换成软链接
if [ -d /app/napcat/config ] && [ ! -L /app/napcat/config ]; then
    cp -a /app/napcat/config/. /data/config/ 2>/dev/null || true
    rm -rf /app/napcat/config
    ln -sfn /data/config /app/napcat/config
fi

mkdir -p /app/.config
if [ -d /app/.config/QQ ] && [ ! -L /app/.config/QQ ]; then
    cp -a /app/.config/QQ/. /data/QQ/ 2>/dev/null || true
    rm -rf /app/.config/QQ
    ln -sfn /data/QQ /app/.config/QQ
elif [ ! -e /app/.config/QQ ]; then
    ln -sfn /data/QQ /app/.config/QQ
fi

wait $EPID
