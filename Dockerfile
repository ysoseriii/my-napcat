FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl python3 unzip && \
    rm -rf /var/lib/apt/lists/*

# 下载 Lagrange.OneBot 自包含构建 (net9.0, linux-x64)
ARG LAGRANGE_TAG=nightly
RUN mkdir -p /app/bin /app/data && \
    curl -fsSL --retry 3 -o /tmp/lagrange.tar.gz \
        "https://github.com/LagrangeDev/Lagrange.Core/releases/download/${LAGRANGE_TAG}/Lagrange.OneBot_linux-x64_net9.0_SelfContained.tar.gz" && \
    tar xzf /tmp/lagrange.tar.gz -C /tmp/lagrange-extract/ && \
    PUBLISH_DIR=$(dirname $(find /tmp/lagrange-extract -name Lagrange.OneBot -type f)) && \
    mv "$PUBLISH_DIR"/* /app/bin/ && \
    rm -rf /tmp/lagrange.tar.gz /tmp/lagrange-extract

WORKDIR /app/data

COPY appsettings.json /app/templates/appsettings.json
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

COPY docker-init.sh /docker-init.sh
RUN chmod +x /docker-init.sh

ENV RUNNING_IN_DOCKER=true

ENTRYPOINT ["bash", "/docker-init.sh"]
