# Agora On-Premise Recording Java SDK —— linux/arm64 运行镜像
# 用已打好的 fat jar + arm64 原生 .so，无需在容器内编译
FROM eclipse-temurin:17-jre-jammy

# 录制/转码需要 ffmpeg（recoverFile / 合并 h264+aac 用），装一下
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# fat jar
COPY lib/agora-example.jar /app/agora-example.jar
# arm64 原生库
COPY lib/native/linux/aarch64/ /app/native/
# 录制配置 + 凭据
COPY config/ /app/config/

ENV LD_LIBRARY_PATH=/app/native
ENV TZ=Asia/Shanghai

# 用 CliLauncher 命令行模式：--configFileName 指向配置，--channel 覆盖频道
# .keys 放在工作目录 /app/.keys（CliLauncher 读相对路径 .keys）
ENTRYPOINT ["/bin/sh","-c","cp -f /app/config/.keys /app/.keys 2>/dev/null; \
  mkdir -p /tmp/recording; \
  exec java \
    -Djava.library.path=/app/native \
    -jar /app/agora-example.jar \
    --mode=cli \
    --configFileName=/app/config/record.json \
    --channel=${CHANNEL}"]
