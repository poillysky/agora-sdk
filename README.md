# agora-sdk

Agora 本地服务端录制（On-Premise Recording Java SDK）容器化工程。
服务器作为「哑客户端」加入 Agora 频道，实时拉流并录制为 MP4。

## 特性

- 基于 `Agora-Recording-Java-SDK` v4.4.151（arm64 原生库）
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
│   └── native/linux/aarch64/*.so        # arm64 原生库
└── recordings/          # 录制输出(挂载)
```

## 使用

1. 修改 `config/.keys` 填入你的 `APP_ID` / `TOKEN`，`docker-compose.yml` 里 `CHANNEL` 填频道名。
2. 构建并启动：

```bash
docker compose build
docker compose up
```

录制文件输出到 `./recordings/`。

## CI/CD：自动构建到 Docker Hub

`.github/workflows/docker-build.yml` 会在推送 `main` 或打 tag 时自动构建镜像并推送到 Docker Hub。

需在仓库配置：

- **Settings → Secrets and variables → Actions → Secrets**：
  - `DOCKERHUB_USERNAME`：Docker Hub 用户名
  - `DOCKERHUB_TOKEN`：Docker Hub Access Token（推荐，别用密码）
- **Variables**（可选）：`IMAGE_NAME` 默认 `poillysky/agora-sdk`

生成的镜像标签：`latest`（main 分支）、分支名、`v1.2.3` 等语义化版本。

## 运行要求

- 平台：`linux/arm64`（Apple Silicon / ARM Linux）。如需 amd64，替换为 x86_64 版 jar + `.so`。
- 网络：录制 SDK 需要绑定大量 UDP 端口（40000–41000）并访问 `.agora.io` / `.agoralab.co`。
  - Linux 主机建议 `network_mode: host`
  - macOS Docker Desktop 不支持 host 网络，需改用端口段映射（`ports: 40000-41000/udp`）
- Token 有时效，长录制需定时刷新 token 重启。

## 安全提示

`config/.keys` 含凭据，请勿提交真实 token 到公开仓库；建议用环境变量或 Secret 注入。
