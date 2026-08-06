#!/usr/bin/env python3
"""
Lance cloudflared, lit l'URL publique HTTPS, met a jour vendia_runtime.json.

Le gateway sert ce fichier en /vendia/runtime.json pour que l'app
memorise le lien distant (usage 4G/5G apres un passage en Wi-Fi).
"""
from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RUNTIME = ROOT / "vendia_runtime.json"
TOOLS = ROOT / "tools"
CF_EXE = TOOLS / "cloudflared.exe"
CF_URL = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
URL_RE = re.compile(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com")


def lan_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def write_runtime(public_url: str | None = None, extra: dict | None = None):
    data = {
        "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "lanUrl": f"http://{lan_ip()}:8765",
        "lanIp": lan_ip(),
        "gatewayPort": 8765,
        "ollamaPort": 11435,
        "publicUrl": public_url,
        "sameOriginV1": True,
    }
    if RUNTIME.exists():
        try:
            old = json.loads(RUNTIME.read_text(encoding="utf-8"))
            if public_url is None and old.get("publicUrl"):
                data["publicUrl"] = old["publicUrl"]
        except Exception:
            pass
    if extra:
        data.update(extra)
    RUNTIME.write_text(json.dumps(data, indent=2), encoding="utf-8")
    return data


def ensure_cloudflared() -> Path:
    TOOLS.mkdir(exist_ok=True)
    if CF_EXE.exists() and CF_EXE.stat().st_size > 1_000_000:
        return CF_EXE
    print("[tunnel] telechargement cloudflared…", flush=True)
    urllib.request.urlretrieve(CF_URL, CF_EXE)
    return CF_EXE


def wait_gateway(timeout=30) -> bool:
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            urllib.request.urlopen("http://127.0.0.1:8765/", timeout=2)
            return True
        except Exception:
            time.sleep(0.5)
    return False


def main():
    write_runtime(None, {"tunnel": "starting"})
    if not wait_gateway(40):
        print("[tunnel] gateway 8765 indisponible — abandon tunnel", flush=True)
        write_runtime(None, {"tunnel": "gateway_down"})
        return 1

    exe = ensure_cloudflared()
    cmd = [str(exe), "tunnel", "--url", "http://127.0.0.1:8765", "--no-autoupdate"]
    print("[tunnel] demarrage cloudflared…", flush=True)
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        cwd=str(ROOT),
    )
    public = None
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            line = line.rstrip()
            if line:
                print(f"[tunnel] {line}", flush=True)
            m = URL_RE.search(line)
            if m:
                public = m.group(0).rstrip("/")
                write_runtime(public, {"tunnel": "up"})
                print(f"\n[tunnel] URL PUBLIQUE (4G/5G) : {public}\n", flush=True)
        proc.wait()
    except KeyboardInterrupt:
        proc.terminate()
    finally:
        write_runtime(public, {"tunnel": "stopped"})
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
