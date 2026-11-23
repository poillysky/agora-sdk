# Agora On-Premise Recording Java SDK —— linux/amd64 运行镜像（NAS/x86_64 专用）
# 用已打好的 fat jar + x86_64 原生 .so，无需在容器内编译
FROM eclipse-temurin:17-jre-jammy

# 录制/转码需要 ffmpeg（recoverFile / 合并 h264+aac 用）
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# fat jar
COPY lib/agora-example.jar /app/agora-example.jar
# x86_64 原生库
COPY lib/native/linux/x86_64/ /app/native/
# 录制配置 + 凭据
COPY config/ /app/config/

ENV LD_LIBRARY_PATH=/app/native
ENV TZ=Asia/Shanghai

ENTRYPOINT ["/bin/sh","-c","cp -f /app/config/.keys /app/.keys 2>/dev/null; \
  mkdir -p /tmp/recording; \
  exec java \
    -Djava.library.path=/app/native \
    -jar /app/agora-example.jar \
    --mode=cli \
    --configFileName=/app/config/record.json \
    --channel=${CHANNEL}"]
