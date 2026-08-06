#!/usr/bin/env python3
"""
Passerelle VendIA — un seul port pour l'app + l'IA Ollama (hébergée sur le PC).

  /              → index.html + assets
  /v1/*          → proxy OpenAI-compatible → Ollama
  /api/*         → proxy API native Ollama
  /vendia/health → statut Ollama + modèles
  /vendia/runtime.json → URLs LAN / tunnel pour le téléphone

Usage :
  python vendia_gateway.py --port 8765 --bind 0.0.0.0 --ollama 127.0.0.1:11435
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import socket
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
OLLAMA = "127.0.0.1:11435"
PORT = 8765


def lan_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def ollama_get(path: str, timeout: float = 3.0):
    url = f"http://{OLLAMA}{path}"
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, resp.read(), resp.headers.get("Content-Type", "application/json")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("[VendIA] %s - %s\n" % (self.address_string(), fmt % args))

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def _json(self, code: int, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self._cors()
        self.end_headers()
        self.wfile.write(data)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path.rstrip("/") or "/"
        if path in ("/vendia/runtime.json", "/vendia/runtime"):
            return self._runtime()
        if path in ("/vendia/health", "/vendia/status"):
            return self._health()
        if path.startswith("/v1/") or path.startswith("/api/") or path in ("/v1", "/api"):
            return self._proxy()
        return self._static()

    def do_POST(self):
        path = urlparse(self.path).path
        if path.startswith("/v1/") or path.startswith("/api/"):
            return self._proxy()
        self.send_error(404)

    def _runtime(self):
        rp = ROOT / "vendia_runtime.json"
        ip = lan_ip()
        base = {
            "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "lanUrl": f"http://{ip}:{PORT}",
            "lanIp": ip,
            "gatewayPort": PORT,
            "ollamaPort": int(OLLAMA.split(":")[-1]) if ":" in OLLAMA else 11435,
            "publicUrl": None,
            "sameOriginV1": True,
            "v1": f"http://{ip}:{PORT}/v1",
            "hint": "Ouvre cette URL sur le téléphone (même Wi‑Fi). Le modèle reste sur le PC.",
        }
        if rp.is_file():
            try:
                old = json.loads(rp.read_text(encoding="utf-8"))
                if old.get("publicUrl"):
                    base["publicUrl"] = old["publicUrl"]
                if old.get("lanUrl"):
                    base["lanUrl"] = old["lanUrl"]
                if old.get("lanIp"):
                    base["lanIp"] = old["lanIp"]
            except Exception:
                pass
        self._json(200, base)

    def _health(self):
        info = {
            "ok": False,
            "gateway": True,
            "ollama": False,
            "ollamaHost": OLLAMA,
            "models": [],
            "hasMoondream": False,
            "lanUrl": f"http://{lan_ip()}:{PORT}/",
            "message": "",
        }
        try:
            status, raw, _ = ollama_get("/api/tags", timeout=1.5)
            if status == 200:
                payload = json.loads(raw.decode("utf-8", errors="replace"))
                models = [m.get("name", "") for m in payload.get("models", [])]
                info["ollama"] = True
                info["models"] = models
                info["hasMoondream"] = any("moondream" in m.lower() for m in models)
                info["ok"] = info["hasMoondream"]
                info["message"] = (
                    "Prêt — modèle moondream sur le PC"
                    if info["hasMoondream"]
                    else "Ollama OK mais moondream manquant — lance 1-INSTALLER.bat"
                )
            else:
                info["message"] = f"Ollama HTTP {status}"
        except Exception as e:
            info["message"] = f"Ollama arrêté. Lance 2-LANCER.bat ({e.__class__.__name__})"
        # Toujours 200 pour que le navigateur / curl affichent le JSON (ok: true/false)
        self._json(200, info)

    def _proxy(self):
        path = self.path
        if path in ("/v1", "/api"):
            path = path + "/"
        target = f"http://{OLLAMA}{path}"
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        headers = {}
        for k in ("Content-Type", "Authorization"):
            if self.headers.get(k):
                headers[k] = self.headers.get(k)
        req = urllib.request.Request(target, data=body, headers=headers, method=self.command)
        try:
            with urllib.request.urlopen(req, timeout=600) as resp:
                data = resp.read()
                self.send_response(resp.status)
                ct = resp.headers.get("Content-Type", "application/json")
                self.send_header("Content-Type", ct)
                self.send_header("Content-Length", str(len(data)))
                self._cors()
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            data = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", e.headers.get("Content-Type", "application/json"))
            self.send_header("Content-Length", str(len(data)))
            self._cors()
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            msg = json.dumps({
                "error": str(e),
                "hint": "Le modèle est sur le PC (Ollama). Vérifie Lancer VendIA.bat",
            }).encode("utf-8")
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(msg)))
            self._cors()
            self.end_headers()
            self.wfile.write(msg)

    def _static(self):
        path = urlparse(self.path).path
        if path in ("", "/"):
            path = "/index.html"
        rel = path.lstrip("/").replace("\\", "/")
        if ".." in rel.split("/"):
            self.send_error(403)
            return
        file_path = (ROOT / rel).resolve()
        if not str(file_path).startswith(str(ROOT.resolve())) or not file_path.is_file():
            self.send_error(404)
            return
        data = file_path.read_bytes()
        ctype = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
        if file_path.suffix.lower() == ".html":
            ctype = "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self._cors()
        self.end_headers()
        self.wfile.write(data)


def main():
    global OLLAMA, PORT
    ap = argparse.ArgumentParser(description="Passerelle VendIA (app + Ollama sur le PC)")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--ollama", default=os.environ.get("VENDIA_OLLAMA", "127.0.0.1:11435"))
    args = ap.parse_args()
    PORT = args.port
    OLLAMA = args.ollama.replace("http://", "").replace("https://", "").rstrip("/")
    httpd = ThreadingHTTPServer((args.bind, args.port), Handler)
    ip = lan_ip()
    print(f"[VendIA] gateway http://{args.bind}:{args.port}/  →  Ollama {OLLAMA}", flush=True)
    print(f"[VendIA] PC     : http://127.0.0.1:{args.port}/", flush=True)
    print(f"[VendIA] Tel Wi‑Fi : http://{ip}:{args.port}/", flush=True)
    print(f"[VendIA] Santé : http://127.0.0.1:{args.port}/vendia/health", flush=True)
    print("[VendIA] Le modèle reste sur cet ordinateur. Ne ferme pas cette fenêtre.", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[VendIA] stop")


if __name__ == "__main__":
    main()
