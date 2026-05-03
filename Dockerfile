FROM mlikiowa/napcat-docker:base

WORKDIR /app

# entrypoint + 配置模板 (来自 NapCat-Docker 上游)
ADD https://raw.githubusercontent.com/NapNeko/NapCat-Docker/main/entrypoint.sh /app/entrypoint.sh
ADD https://raw.githubusercontent.com/NapNeko/NapCat-Docker/main/templates/ws.json /app/templates/ws.json
ADD https://raw.githubusercontent.com/NapNeko/NapCat-Docker/main/templates/astrbot.json /app/templates/astrbot.json
ADD https://raw.githubusercontent.com/NapNeko/NapCat-Docker/main/templates/koishi.json /app/templates/koishi.json

# 下载 NapCat Shell 跨平台版 (从 GitHub Releases)
ARG NAPCAT_VERSION=v4.18.1
ADD https://github.com/NapNeko/NapCatQQ/releases/download/${NAPCAT_VERSION}/NapCat.Shell.zip /app/NapCat.Shell.zip

# 安装 QQ Linux (amd64 / arm64 自适应)
RUN arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    for i in $(seq 1 5); do \
        curl -L --retry 3 -o linuxqq.deb \
            "https://dldir1v6.qq.com/qqfile/qq/QQNT/f9cbaab2/linuxqq_3.2.28-48517_${arch}.deb" && break; \
        sleep 5; \
    done && \
    dpkg -i --force-depends linuxqq.deb && \
    rm linuxqq.deb

# 注入 NapCat 加载器
RUN echo '(async () => {await import("file:///app/napcat/napcat.mjs");})();' > /opt/QQ/resources/app/loadNapCat.js && \
    sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' /opt/QQ/resources/app/package.json

VOLUME /app/napcat/config
VOLUME /app/.config/QQ

ENTRYPOINT ["bash", "entrypoint.sh"]
