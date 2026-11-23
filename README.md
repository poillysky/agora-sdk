# agora-sdk

Agora 本地服务端录制（On-Premise Recording Java SDK）容器化工程。
服务器作为「哑客户端」加入 Agora 频道，实时拉流并录制为 MP4。

## 特性

- 基于 `Agora-Recording-Java-SDK` v4.4.151（x86_64 原生库，适配 amd64 NAS/Linux）
- 已内置编译好的 `agora-example.jar`，容器无需再编译
- 录制参数保障「断网不丢、音画不错位、画质无损」：
  - `recoverFile: true` —— 崩溃/断流也能恢复 h264+aac 原始文件，不丢片
  - `recordEncodedOnly: true` + `subscribeEncodedFrameOnly: true` —— 编码帧直录，不重编码，画质无损、省 CPU
  - 单流录制，每个 uid 一个 mp4，音画由 SDK 内部同步
- GitHub Actions 自动构建并推送 Docker Hub

## 目录结构

```
.
├── Dockerfile
├── docker-compose.yml
├── .github/workflows/docker-build.yml   # CI: 构建并推送 Docker Hub
├── config/
│   ├── record.json      # 录制参数
│   └── .keys            # APP_ID / TOKEN
├── lib/
│   ├── agora-example.jar
│   └── native/linux/x86_64/*.so         # x86_64 原生库
└── recordings/          # 录制输出(挂载)
```

## 使用（常驻录制服务 + REST 动态开录）

容器跑的是 **Spring Boot web 服务**（默认端口 8080），通过 REST 接口**实时把房间信息发进去开录**，一个容器可并发录多路。

```bash
docker compose up -d --build
```

### 开录（带房间信息）
```bash
curl -X POST http://NAS_IP:8080/api/recording/startByRoom \
  -H "Content-Type: application/json" \
  -d '{"appid":"xxx","channel":"房间频道","token":"xxx","name":"房间名","duration":7200}'
# 返回 {"code":0,"taskId":"...","channel":"..."}
```

### 停录
```bash
curl "http://NAS_IP:8080/api/recording/stop?taskId=<taskId>"
```

### 查看状态 / 全部停止
```bash
curl http://NAS_IP:8080/api/recording/
curl http://NAS_IP:8080/api/recording/destroy
```

成品视频保存到宿主机 `./recordings/`（容器内 `/tmp/recording/`），
每路一个 mp4，`recoverFile=true` 断网/崩溃也能恢复不丢。

Python 对接示例见 `client/baoyu_recorder_client.py`（对接你现有 gateway 凭据系统）。

## CI/CD：自动构建到 Docker Hub

`.github/workflows/docker-build.yml` 会在推送 `main` 或打 tag 时自动构建镜像并推送到 Docker Hub。

需在仓库配置：

- **Settings → Secrets and variables → Actions → Secrets**：
  - `DOCKERHUB_USERNAME`：Docker Hub 用户名
  - `DOCKERHUB_TOKEN`：Docker Hub Access Token（推荐，别用密码）
- **Variables**（可选）：`IMAGE_NAME` 默认 `poillysky/agora-sdk`

生成的镜像标签：`latest`（main 分支）、分支名、`v1.2.3` 等语义化版本。

## 运行要求

- 平台：`linux/amd64`（x86_64 NAS / Linux 服务器）。本仓库 jar 与 `.so` 均为 x86_64 版。
- 网络：录制 SDK 需要绑定大量 UDP 端口（40000–41000）并访问 `.agora.io` / `.agoralab.co`。
  - NAS/Linux 主机用 `network_mode: host`（群晖/威联通等 NAS 的 Docker 原生支持）

- Token 有时效，长录制需定时刷新 token 重启。

## 安全提示

`config/.keys` 含凭据，请勿提交真实 token 到公开仓库；建议用环境变量或 Secret 注入。
