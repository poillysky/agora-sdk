#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
baoyu 监控 → agora-sdk 录制服务 对接示例（方案 A / push 模式）

流程:
  1. baoyu 监控检测到某房间开播
  2. 用现有 capabilities 拿 credentials (appid/channel/token)
  3. 调录制服务 POST /api/recording/startByRoom 开录
  4. 主播下播/超时 → POST/GET /api/recording/stop?taskId=xxx 停录
  5. 成品在录制服务容器的 /tmp/recording/ (即宿主机 ./recordings/)
"""
import json
import time
import requests

# 录制服务地址（NAS 上 docker 部署, host 网络, 默认 8080）
RECORDER_BASE = "http://NAS_IP:8080"


def start_room(appid: str, channel: str, token: str,
               name: str = "", duration: int = 7200) -> dict:
    """按房间信息开录，返回 {code, taskId, channel}"""
    payload = {
        "appid": appid,
        "channel": channel,
        "token": token,
        "name": name or channel,
        "duration": duration,      # 秒, 到点自动停
    }
    r = requests.post(f"{RECORDER_BASE}/api/recording/startByRoom",
                      json=payload, timeout=15)
    r.raise_for_status()
    return r.json()


def stop_task(task_id: str) -> dict:
    """停止某路录制（SSE 接口，这里只读第一段事件即返回）"""
    r = requests.get(f"{RECORDER_BASE}/api/recording/stop",
                     params={"taskId": task_id}, timeout=15, stream=True)
    r.raise_for_status()
    # SSE 流, 取几行文本即可（真正停逻辑在服务端已执行）
    lines = []
    for line in r.iter_lines(decode_unicode=True):
        if line:
            lines.append(line)
        if len(lines) > 20:
            break
    return {"raw": "\n".join(lines)}


def list_status() -> str:
    r = requests.get(f"{RECORDER_BASE}/api/recording/", timeout=10)
    r.raise_for_status()
    return r.text


# ---------- 与 baoyu 现有凭据系统对接（示意） ----------
def fetch_credentials(room_id: str, plat_id: int) -> dict:
    """
    复用 baoyu 现有逻辑:
      from gateway import get_stream_credentials
      cred = gateway.get_stream_credentials(room_id, plat_id)
    密语(474) 返回含 appid / channel / token。
    这里用占位，实际接到你 baoyu gateway。
    """
    # cred = gateway.get_stream_credentials(room_id, plat_id)
    cred = {
        "appid": "APP_ID",
        "channel": "CHANNEL_NAME",
        "token": "TOKEN_007e_or_ext",
    }
    return cred


if __name__ == "__main__":
    # 示例: 录密语某房间 2 小时
    room_id, plat_id = "6516436", 474
    cred = fetch_credentials(room_id, plat_id)

    resp = start_room(cred["appid"], cred["channel"], cred["token"],
                      name=f"miyu_{room_id}", duration=7200)
    print("start:", resp)

    task_id = resp.get("taskId")
    print("录制中... taskId =", task_id)

    # —— 生产环境: 这里应循环监听房间是否下播, 下播则 stop ——
    # time.sleep(7200)
    # print(stop_task(task_id))
