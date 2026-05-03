FROM mlikiowa/napcat-docker:latest

# 预解压 NapCat，避免运行时 unzip 跟 volume 软链接冲突
RUN unzip -o /app/NapCat.Shell.zip -d /app/NapCat.Shell/ && \
    cp -r /app/NapCat.Shell/* /app/ && \
    rm -rf /app/NapCat.Shell/

# 运行时需要初始化的空目录（entrypoint 会检测并跳过）
RUN mkdir -p /app/napcat/config /app/.config/QQ

# 运行时将 /app/napcat/config 和 /app/.config/QQ 的内容导向 /data
# 使用 init 脚本在 volume mount 之后处理
COPY docker-init.sh /docker-init.sh
RUN chmod +x /docker-init.sh

ENTRYPOINT ["bash", "/docker-init.sh"]
