#!/usr/bin/env python3
"""
Passerelle VendIA — un seul port pour l'app + l'IA Ollama.

  /          → fichiers statiques (index.html, …)
  /v1/*      → proxy → Ollama OpenAI-compatible
  /api/*     → proxy → Ollama API native (tags, etc.)

Usage (LAN ou derrière cloudflared / ngrok) :
  python vendia_gateway.py --port 8765 --ollama 127.0.0.1:11435

Sur 4G/5G : exposer CE port via tunnel HTTPS, puis ouvrir l'URL publique.
L'app détecte l'hôte et appelle /v1 sur la même origine (pas de mixed content).
"""
from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
OLLAMA = "127.0.0.1:11435"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("[VendIA] %s - %s\n" % (self.address_string(), fmt % args))

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/vendia/runtime.json", "/vendia/runtime"):
            return self._runtime()
        if path.startswith("/v1/") or path.startswith("/api/"):
            return self._proxy()
        return self._static()

    def do_POST(self):
        path = urlparse(self.path).path
        if path.startswith("/v1/") or path.startswith("/api/"):
            return self._proxy()
        self.send_error(404)

    def _runtime(self):
        """Config live pour que l'app s'adapte Wi‑Fi / 4G."""
        rp = ROOT / "vendia_runtime.json"
        if rp.is_file():
            data = rp.read_bytes()
        else:
            data = json.dumps({
                "lanUrl": None,
                "publicUrl": None,
                "gatewayPort": 8765,
                "ollamaPort": 11435,
                "sameOriginV1": True,
            }).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self._cors()
        self.end_headers()
        self.wfile.write(data)

    def _proxy(self):
        path = self.path  # inclut query string
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
            msg = json.dumps({"error": str(e)}).encode("utf-8")
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
        # sécurité : pas de path traversal
        rel = path.lstrip("/").replace("\\", "/")
        if ".." in rel.split("/"):
            self.send_error(403)
            return
        file_path = (ROOT / rel).resolve()
        if not str(file_path).startswith(str(ROOT)) or not file_path.is_file():
            self.send_error(404)
            return
        data = file_path.read_bytes()
        ctype = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self._cors()
        self.end_headers()
        self.wfile.write(data)


def main():
    global OLLAMA
    ap = argparse.ArgumentParser(description="Passerelle VendIA (app + Ollama)")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--ollama", default=os.environ.get("VENDIA_OLLAMA", "127.0.0.1:11435"))
    args = ap.parse_args()
    OLLAMA = args.ollama.replace("http://", "").replace("https://", "").rstrip("/")
    httpd = ThreadingHTTPServer((args.bind, args.port), Handler)
    print(f"[VendIA] gateway http://{args.bind}:{args.port}/  →  Ollama {OLLAMA}", flush=True)
    print("[VendIA] LAN : http://<IP-PC>:%d/" % args.port, flush=True)
    print("[VendIA] 4G  : expose ce port avec cloudflared / ngrok (voir Lancer VendIA Distant.bat)", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[VendIA] stop")


if __name__ == "__main__":
    main()
