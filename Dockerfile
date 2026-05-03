FROM mlikiowa/napcat-docker:latest

# 预解压 NapCat（避免运行时 volume 冲突）
RUN unzip -o /app/NapCat.Shell.zip -d /app/NapCat.Shell/ && \
    cp -r /app/NapCat.Shell/* /app/ && \
    rm -rf /app/NapCat.Shell/ && \
    mkdir -p /app/napcat/config /app/.config/QQ

COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

COPY docker-init.sh /docker-init.sh
RUN chmod +x /docker-init.sh

ENTRYPOINT ["bash", "/docker-init.sh"]
