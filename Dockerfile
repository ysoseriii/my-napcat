FROM mlikiowa/napcat-docker:latest

# 预解压 NapCat，避免运行时 unzip 跟 volume 软链接冲突
RUN unzip -o /app/NapCat.Shell.zip -d /app/NapCat.Shell/ && \
    cp -r /app/NapCat.Shell/* /app/ && \
    rm -rf /app/NapCat.Shell/

# 空目录（entrypoint 会检测并跳过）
RUN mkdir -p /app/napcat/config /app/.config/QQ

# 定时消息脚本
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# init 脚本 (volume mount 后运行)
COPY docker-init.sh /docker-init.sh
RUN chmod +x /docker-init.sh

ENTRYPOINT ["bash", "/docker-init.sh"]
