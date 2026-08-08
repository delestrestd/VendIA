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


# Erreurs réseau "normales" (Chrome ferme la connexion, refresh, etc.)
_BENIGN_NET = (
    ConnectionResetError,
    ConnectionAbortedError,
    BrokenPipeError,
    TimeoutError,
)


class Handler(BaseHTTPRequestHandler):
    # HTTP/1.0 évite des half-open keep-alive qui plantent en traceback sur Windows
    protocol_version = "HTTP/1.0"
    timeout = 120

    def log_message(self, fmt, *args):
        sys.stderr.write("[VendIA] %s - %s\n" % (self.address_string(), fmt % args))

    def handle(self):
        """Ignore les déconnexions client (WinError 10054) — ce n'est PAS une panne serveur."""
        try:
            super().handle()
        except _BENIGN_NET:
            pass
        except Exception as e:
            # Autres erreurs : log court sans stack complète si c'est du réseau
            if "10054" in str(e) or "10053" in str(e):
                return
            raise

    def handle_one_request(self):
        try:
            super().handle_one_request()
        except _BENIGN_NET:
            pass

    def finish(self):
        try:
            super().finish()
        except _BENIGN_NET:
            pass

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Connection", "close")

    def _json(self, code: int, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self._cors()
        self.end_headers()
        try:
            self.wfile.write(data)
        except _BENIGN_NET:
            pass

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
        if path in ("/phone", "/mobile", "/tel"):
            return self._phone_page()
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

    def _phone_page(self):
        """Page PC : QR + URL pour ouvrir VendIA sur le téléphone (objectif principal)."""
        ip = lan_ip()
        phone_url = f"http://{ip}:{PORT}/"
        # health rapide
        ok = False
        msg = "Ollama non detecte"
        try:
            st, raw, _ = ollama_get("/api/tags", timeout=1.5)
            if st == 200:
                payload = json.loads(raw.decode("utf-8", errors="replace"))
                models = [m.get("name", "") for m in payload.get("models", [])]
                ok = any("moondream" in m.lower() for m in models)
                msg = "IA prete (moondream)" if ok else "Ollama OK mais moondream manquant"
        except Exception:
            msg = "Ollama arrete — relance 2-LANCER.bat"

        # QR via API publique (si offline, l'URL texte reste)
        from urllib.parse import quote
        qr = f"https://api.qrserver.com/v1/create-qr-code/?size=280x280&margin=10&data={quote(phone_url, safe='')}"
        status_color = "#059669" if ok else "#d97706"
        status_bg = "#ecfdf5" if ok else "#fffbeb"

        html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>VendIA — Ouvre sur ton téléphone</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0; min-height: 100vh; font-family: system-ui, -apple-system, Segoe UI, sans-serif;
      background: linear-gradient(165deg, #e8eef5, #f4f7fb 40%, #eef2f7);
      color: #0f172a; display: flex; align-items: center; justify-content: center; padding: 1.25rem;
    }}
    .card {{
      width: 100%; max-width: 420px; background: rgba(255,255,255,0.85);
      backdrop-filter: blur(16px); border-radius: 1.5rem; padding: 1.5rem 1.25rem 1.75rem;
      box-shadow: 0 12px 40px -12px rgba(15,23,42,0.18); border: 1px solid rgba(255,255,255,0.7);
      text-align: center;
    }}
    h1 {{ font-size: 1.35rem; margin: 0 0 0.35rem; letter-spacing: -0.02em; }}
    .sub {{ color: #64748b; font-size: 0.9rem; margin: 0 0 1.25rem; line-height: 1.4; }}
    .qr {{
      background: #fff; border-radius: 1rem; padding: 0.75rem; display: inline-block;
      box-shadow: 0 4px 16px -4px rgba(15,23,42,0.12); margin-bottom: 1rem;
    }}
    .qr img {{ display: block; width: 260px; height: 260px; max-width: 70vw; height: auto; }}
    .url {{
      font-size: 1.05rem; font-weight: 800; word-break: break-all;
      background: #0f766e; color: #fff; padding: 0.85rem 1rem; border-radius: 0.9rem;
      margin: 0.5rem 0 0.75rem; line-height: 1.35;
    }}
    .steps {{ text-align: left; font-size: 0.88rem; color: #334155; margin: 1rem 0 0; padding: 0; list-style: none; }}
    .steps li {{
      padding: 0.55rem 0.65rem; margin-bottom: 0.4rem; border-radius: 0.75rem;
      background: #f1f5f9; display: flex; gap: 0.55rem; align-items: flex-start;
    }}
    .steps b {{
      flex-shrink: 0; width: 1.35rem; height: 1.35rem; border-radius: 999px;
      background: #0f766e; color: #fff; font-size: 0.75rem; display: flex;
      align-items: center; justify-content: center;
    }}
    .status {{
      display: inline-flex; align-items: center; gap: 0.4rem; font-size: 0.8rem; font-weight: 600;
      padding: 0.35rem 0.75rem; border-radius: 999px; margin-bottom: 1rem;
      background: {status_bg}; color: {status_color};
    }}
    .dot {{ width: 8px; height: 8px; border-radius: 999px; background: {status_color}; }}
    button, .btn {{
      display: block; width: 100%; border: 0; border-radius: 0.9rem; padding: 0.85rem 1rem;
      font-size: 0.95rem; font-weight: 700; cursor: pointer; margin-top: 0.5rem; text-decoration: none;
    }}
    .btn-copy {{ background: #0f766e; color: #fff; }}
    .btn-pc {{ background: #e2e8f0; color: #0f172a; }}
    .hint {{ font-size: 0.75rem; color: #94a3b8; margin-top: 1rem; line-height: 1.4; }}
    .warn {{
      font-size: 0.8rem; color: #b45309; background: #fffbeb; border-radius: 0.75rem;
      padding: 0.65rem 0.75rem; margin-top: 0.75rem; text-align: left; line-height: 1.35;
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="status"><span class="dot"></span> {msg}</div>
    <h1>Ouvre VendIA sur ton téléphone</h1>
    <p class="sub">Le PC reste allumé (IA). Le téléphone sert à prendre les photos.</p>

    <div class="qr">
      <img src="{qr}" alt="QR code VendIA" width="280" height="280"
           onerror="this.parentElement.innerHTML='<p style=\\'padding:2rem;color:#64748b\\'>QR indisponible hors-ligne — tape l’URL ci-dessous</p>'" />
    </div>

    <div class="url" id="phone-url">{phone_url}</div>
    <button type="button" class="btn-copy" onclick="copyUrl()">Copier le lien téléphone</button>
    <a class="btn btn-pc" href="/">Ouvrir l’app sur ce PC</a>

    <ol class="steps">
      <li><b>1</b><span>Téléphone et PC sur le <strong>même Wi‑Fi</strong> (pas le partage 4G du tel)</span></li>
      <li><b>2</b><span><strong>Scanne le QR</strong> ou colle le lien dans Safari / Chrome</span></li>
      <li><b>3</b><span>Autorise la caméra → photo → analyse IA</span></li>
    </ol>

    <div class="warn">
      Si le téléphone ne charge pas la page : sur le PC, lance
      <strong>3-OUVRIR-RESEAU.bat</strong> en Administrateur, puis relance
      <strong>2-LANCER.bat</strong>.
    </div>
    <p class="hint">Laisse les fenêtres VendIA-Ollama et VendIA-Gateway ouvertes sur le PC.</p>
  </div>
  <script>
    function copyUrl() {{
      const u = document.getElementById('phone-url').textContent.trim();
      if (navigator.clipboard && navigator.clipboard.writeText) {{
        navigator.clipboard.writeText(u).then(function() {{ alert('Lien copié : ' + u); }});
      }} else {{
        prompt('Copie ce lien :', u);
      }}
    }}
  </script>
</body>
</html>"""
        data = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self._cors()
        self.end_headers()
        try:
            self.wfile.write(data)
        except _BENIGN_NET:
            pass

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
        try:
            self.wfile.write(data)
        except _BENIGN_NET:
            pass


class QuietThreadingHTTPServer(ThreadingHTTPServer):
    """Ne pollue pas la console avec ConnectionResetError (navigateur qui coupe)."""

    daemon_threads = True
    request_queue_size = 32

    def handle_error(self, request, client_address):
        exc = sys.exc_info()[1]
        if isinstance(exc, _BENIGN_NET):
            return
        if exc and ("10054" in str(exc) or "10053" in str(exc) or "Broken pipe" in str(exc)):
            return
        # Vraie erreur : message court
        sys.stderr.write(
            "[VendIA] erreur requête %s : %s\n" % (client_address, exc.__class__.__name__ if exc else "?")
        )


def main():
    global OLLAMA, PORT
    ap = argparse.ArgumentParser(description="Passerelle VendIA (app + Ollama sur le PC)")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--bind", default="0.0.0.0")
    ap.add_argument("--ollama", default=os.environ.get("VENDIA_OLLAMA", "127.0.0.1:11435"))
    args = ap.parse_args()
    PORT = args.port
    OLLAMA = args.ollama.replace("http://", "").replace("https://", "").rstrip("/")
    httpd = QuietThreadingHTTPServer((args.bind, args.port), Handler)
    ip = lan_ip()
    print(f"[VendIA] gateway → Ollama {OLLAMA}", flush=True)
    print(f"[VendIA] MOBILE (principal) : http://{ip}:{args.port}/", flush=True)
    print(f"[VendIA] QR + aide         : http://127.0.0.1:{args.port}/phone", flush=True)
    print(f"[VendIA] PC                : http://127.0.0.1:{args.port}/", flush=True)
    print(f"[VendIA] Sante             : http://127.0.0.1:{args.port}/vendia/health", flush=True)
    print("[VendIA] Objectif = telephone. Laisse cette fenetre ouverte.", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[VendIA] stop")


if __name__ == "__main__":
    main()
