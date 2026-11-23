# Agora On-Premise Recording Java SDK —— linux/amd64 常驻录制服务（NAS/x86_64）
# 跑 Spring Boot web 服务，通过 REST 动态按房间信息开录。
FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY lib/agora-example.jar /app/agora-example.jar
COPY lib/native/linux/x86_64/ /app/native/
COPY config/ /app/config/

ENV LD_LIBRARY_PATH=/app/native
ENV TZ=Asia/Shanghai

# 从 /app/config/.keys 拷一份到工作目录（SDK 默认读 ./\.keys，作兜底 appid/token）
RUN cp -f /app/config/.keys /app/.keys 2>/dev/null || true

EXPOSE 8080

# 直接 java -jar = 起 Spring Boot web 服务（Start-Class=DemoApplication，默认端口8080）
# 录制输出目录指向本地挂载 /tmp/recording
ENTRYPOINT ["java", \
  "-Djava.library.path=/app/native", \
  "-Dserver.port=8080", \
  "-jar", "/app/agora-example.jar"]
