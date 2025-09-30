#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Add a new lecture video row to raw_video_links.csv

Flow
1) yt-dlp로 메타 조회 후 로컬 mp4 다운로드 (H.264/AAC, faststart)
2) 내장 HTTP 서버(127.0.0.1)로 파일 서빙 → <video>에서 http://... 로 재생
3) 버튼: 타임스탬프 추가/되돌리기/수동 입력/CSV 저장/파일 삭제/외부 플레이어 열기
4) 저장 후 슬라이드 추출 & ASR 안내

Deps: pandas, yt-dlp, pywebview, (ffmpeg 권장)
Python: 3.9+
"""

import os
import sys
import json
import shutil
import platform
import subprocess
import threading
import socket
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from urllib.parse import quote

import pandas as pd
import tkinter as tk
from tkinter import messagebox, filedialog
from yt_dlp import YoutubeDL
import webview

CSV_DEFAULT = os.path.join(os.getcwd(), "raw_video_links.csv")
DOWNLOAD_DIR = os.path.join(os.getcwd(), "_downloads")

def _ensure_dir(p):
    os.makedirs(p, exist_ok=True)
    return p

# ---------------- HTTP server to serve DOWNLOAD_DIR ---------------- #
class _StaticHandler(SimpleHTTPRequestHandler):
    # Serve files from DOWNLOAD_DIR only
    def translate_path(self, path):
        # remove query/fragment
        path = path.split('?', 1)[0].split('#', 1)[0]
        # leading '/'
        if path.startswith('/'):
            path = path[1:]
        # Map to DOWNLOAD_DIR
        local = os.path.normpath(os.path.join(DOWNLOAD_DIR, path))
        # prevent path escape
        if not os.path.abspath(local).startswith(os.path.abspath(DOWNLOAD_DIR)):
            return DOWNLOAD_DIR
        return local

    # Less noisy logs
    def log_message(self, fmt, *args):
        pass

def _pick_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]

class LocalServer:
    def __init__(self, root_dir):
        _ensure_dir(root_dir)
        self.port = _pick_free_port()
        self.httpd = ThreadingHTTPServer(('127.0.0.1', self.port), _StaticHandler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    def start(self):
        self.thread.start()

    def stop(self):
        try:
            self.httpd.shutdown()
        except Exception:
            pass

# ---------------- GUI HTML ---------------- #
HTML_TEMPLATE = r"""
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Add New Video</title>
  <style>
    body { font-family: -apple-system, system-ui, Segoe UI, Roboto, Helvetica, Arial, sans-serif; margin: 16px; }
    .row { margin-bottom: 12px; }
    input[type=text] { width: 520px; padding: 8px; }
    label { display: inline-block; min-width: 140px; }
    button { padding: 8px 14px; margin-right: 8px; }
    #playerBox { margin-top: 16px; }
    video { width: 100%; max-width: 920px; height: auto; background: #000; }
    #timestamps { margin-top: 12px; background: #f7f7f7; padding: 10px; border-radius: 6px; max-height: 160px; overflow: auto; }
    .muted { color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <h2>Add a New Lecture Video</h2>

  <div id="step1">
    <div class="row">
      <label>YouTube URL</label>
      <input id="url" type="text" placeholder="https://www.youtube.com/watch?v=..." />
    </div>
    <div class="row">
      <label>Speaker</label>
      <input id="speaker" type="text" placeholder="e.g., bio-4 / dental / speaking" />
    </div>
    <div class="row">
      <label>Learning Objectives</label>
      <input id="lo" type="text" placeholder="none" />
    </div>
    <div class="row">
      <label>CSV Path</label>
      <input id="csv" type="text" />
      <button onclick="pickCsv()">Browse…</button>
    </div>
    <div class="row">
      <button onclick="prepare()">Fetch & Download</button>
    </div>
    <div class="muted">
      The video will be downloaded locally (mp4, H.264/AAC, faststart) and played here via a local server for precise timestamps.
    </div>
  </div>

  <div id="step2" style="display:none;">
    <div class="row">
      <b id="title"></b>
      <span id="meta" class="muted"></span>
    </div>
    <div id="playerBox">
      <video id="player" controls autoplay muted playsinline webkit-playsinline preload="metadata"></video>
    </div>

    <div class="row" style="margin-top:10px;">
      <button onclick="addTs()">+ Add timestamp</button>
      <button onclick="undoTs()">Undo</button>
      <input id="manualSec" type="text" placeholder="sec (e.g., 123.456)" style="width:150px; margin-left:8px;">
      <button onclick="addManualTs()">Add (manual)</button>
      <button onclick="saveRow()">Save & Append to CSV</button>
      <button onclick="deleteVideo()" id="delbtn" style="background:#eee;">Delete Video File</button>
      <button onclick="openExternal()">Open in External Player</button>
    </div>

    <div id="timestamps">
      <b>Timestamps</b>
      <div id="tslist" class="muted">No timestamps yet.</div>
    </div>
  </div>

  <script>
    let player = null;
    let url = null;
    let speaker = null;
    let lo = null;
    let csvPath = null;

    let videoId = null;
    let videoTitle = null;
    let durationSec = null;  // yt-dlp metadata
    let localHttpUrl = null; // http://127.0.0.1:<port>/<file>

    let timestamps = [];

    function setTimestampsView() {
      const el = document.getElementById('tslist');
      if (timestamps.length === 0) {
        el.innerText = 'No timestamps yet.';
      } else {
        el.innerText = timestamps.join(' | ');
      }
    }

    async function pickCsv() {
      const chosen = await window.pywebview.api.pick_csv();
      if (chosen) {
        document.getElementById('csv').value = chosen;
      }
    }

    async function prepare() {
      url = document.getElementById('url').value.trim();
      speaker = document.getElementById('speaker').value.trim();
      lo = (document.getElementById('lo').value.trim() || 'none');
      csvPath = document.getElementById('csv').value.trim();

      if (!url) { alert('Please enter a YouTube URL'); return; }
      if (!speaker) { alert('Please enter a speaker'); return; }
      if (!csvPath) { alert('Please set CSV path'); return; }

      const info = await window.pywebview.api.fetch_and_download(url);
      if (!info || !info.ok) {
        alert('Download failed: ' + (info && info.msg ? info.msg : 'unknown'));
        return;
      }
      videoId = info.video_id;
      videoTitle = info.title || '';
      durationSec = info.duration || 0;
      localHttpUrl = info.http_url;

      document.getElementById('title').innerText = videoTitle || '(No title)';
      document.getElementById('meta').innerText = `  • ID: ${videoId}  • Duration: ${durationSec}s`;

      const v = document.getElementById('player');
      v.pause();
      v.removeAttribute('src');
      v.innerHTML = '';

      const src = document.createElement('source');
      src.src = localHttpUrl;   // http://127.0.0.1:<port>/<file>
      src.type = 'video/mp4';
      v.appendChild(src);

      v.onloadedmetadata = function() {
        if (!durationSec || durationSec === 0) {
          try {
            durationSec = Math.floor(v.duration);
            document.getElementById('meta').innerText =
              `  • ID: ${videoId}  • Duration: ${durationSec}s`;
          } catch(e){}
        }
      };

      v.load();
      v.play().catch(() => {});
      player = v;

      document.getElementById('step1').style.display = 'none';
      document.getElementById('step2').style.display = 'block';
    }

    function addTs() {
      if (!player) return;
      const t = player.currentTime || 0;
      const ts = Math.round(t * 10000) / 10000;
      timestamps.push(ts);
      setTimestampsView();
    }

    function addManualTs() {
      const v = document.getElementById('manualSec').value.trim();
      if (!v) return;
      const num = Number(v);
      if (!isFinite(num) || num < 0) {
        alert('Enter a non-negative number in seconds, e.g., 123.456');
        return;
      }
      const ts = Math.round(num * 10000) / 10000;
      timestamps.push(ts);
      setTimestampsView();
      document.getElementById('manualSec').value = '';
    }

    function undoTs() {
      if (timestamps.length > 0) {
        timestamps.pop();
        setTimestampsView();
      }
    }

    async function saveRow() {
      const payload = {
        url: url,
        speaker: speaker,
        lo: lo,
        csv: csvPath,
        video_id: videoId,
        duration: durationSec,
        timestamps: timestamps
      };
      const res = await window.pywebview.api.save_row(JSON.stringify(payload));
      if (res && res.ok) {
        alert('Saved to CSV.\n\nNext:\n  - Run slide extraction:\n    python3 extract_slide_imgs_from_youtube.py --csv raw_video_links.csv --outdir slide_img\n  - Add ASR transcripts before training.');
      } else {
        alert('Failed to save row: ' + (res && res.msg ? res.msg : 'unknown error'));
      }
    }

    async function deleteVideo() {
      const res = await window.pywebview.api.delete_video();
      if (res && res.ok) {
        alert('Deleted.');
        document.getElementById('player').src = '';
      } else {
        alert('Delete failed: ' + (res && res.msg ? res.msg : 'unknown error'));
      }
    }

    async function openExternal() {
      const res = await window.pywebview.api.open_external();
      if (res && !res.ok) {
        alert('Failed to open: ' + (res.msg || 'unknown'));
      }
    }
  </script>
</body>
</html>
"""

# ---------------- Bridge (Python <-> JS) ---------------- #
class Bridge:
    def __init__(self, server: LocalServer):
        self.server = server
        self.last_local_path = None  # absolute path of last downloaded file

    def pick_csv(self):
        root = tk.Tk(); root.withdraw()
        initial = CSV_DEFAULT if os.path.exists(os.path.dirname(CSV_DEFAULT)) else os.getcwd()
        path = filedialog.asksaveasfilename(
            title="Select or create raw_video_links.csv",
            initialdir=os.path.dirname(initial),
            initialfile=os.path.basename(CSV_DEFAULT),
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )
        root.destroy()
        return path or None

    def fetch_and_download(self, url: str):
        """
        - extract metadata (id, title, duration)
        - download mp4 (H.264/AAC, faststart) into DOWNLOAD_DIR
        - return http url served by local server
        """
        try:
            _ensure_dir(DOWNLOAD_DIR)

            # Metadata
            meta_opts = {"quiet": True, "skip_download": True}
            with YoutubeDL(meta_opts) as ydl:
                info = ydl.extract_info(url, download=False)
            vid = info.get("id")
            title = info.get("title") or ""
            duration = info.get("duration") or 0

            # Download options
            outtmpl = os.path.join(DOWNLOAD_DIR, "%(id)s.%(ext)s")
            ydl_opts = {
                "quiet": False,
                "outtmpl": outtmpl,
                "merge_output_format": "mp4",
                "format": "bestvideo[vcodec^=avc1][ext=mp4]+bestaudio[acodec^=mp4a]/best[ext=mp4]/(bestvideo*+bestaudio)/best",
                "restrictfilenames": True,
                "prefer_ffmpeg": True,
                "postprocessors": [
                    {"key": "FFmpegVideoConvertor", "preferedformat": "mp4"},
                ],
                "postprocessor_args": ["-movflags", "+faststart"],
            }
            with YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])

            # Resolve file
            cand_mp4 = os.path.join(DOWNLOAD_DIR, f"{vid}.mp4")
            if not os.path.exists(cand_mp4):
                files = [f for f in os.listdir(DOWNLOAD_DIR) if f.startswith(vid + ".")]
                if not files:
                    raise FileNotFoundError("Downloaded file not found")
                cand_mp4 = os.path.join(DOWNLOAD_DIR, files[0])

            self.last_local_path = os.path.abspath(cand_mp4)
            filename = os.path.basename(self.last_local_path)
            http_url = f"http://127.0.0.1:{self.server.port}/{quote(filename)}"

            return {
                "ok": True,
                "video_id": vid,
                "title": title,
                "duration": int(duration),
                "local_path": self.last_local_path,
                "http_url": http_url,
            }
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def save_row(self, payload_json: str):
        try:
            payload = json.loads(payload_json)
            url = payload["url"]
            speaker = payload["speaker"]
            lo = payload.get("lo", "none") or "none"
            csv_path = payload["csv"]
            video_id = payload["video_id"]
            duration = payload.get("duration", 0)
            timestamps = payload.get("timestamps", [])

            start_list = "Start Time" + ("|" + "|".join(f"{t:.4f}".rstrip("0").rstrip(".") for t in timestamps) if timestamps else "")
            seconds_field = f"{float(duration):.2f}".rstrip("0").rstrip(".")
            video_file = f"{video_id}.mp4"

            row = {
                "Answer.startTimeList": start_list,
                "seconds": seconds_field,
                "speaker": speaker,
                "video_id": video_file,
                "youtube_url": url,
                "learning_objectives": lo,
            }
            columns = ["Answer.startTimeList", "seconds", "speaker", "video_id", "youtube_url", "learning_objectives"]
            df_row = pd.DataFrame([row], columns=columns)

            if os.path.exists(csv_path):
                df_row.to_csv(csv_path, mode="a", index=False, header=False, encoding="utf-8")
            else:
                df_row.to_csv(csv_path, mode="w", index=False, header=True, encoding="utf-8")

            root = tk.Tk(); root.withdraw()
            messagebox.showinfo(
                "Saved",
                "Row appended to CSV.\n\nNext steps:\n"
                "1) Extract slides:\n"
                "   python3 extract_slide_imgs_from_youtube.py --csv raw_video_links.csv --outdir slide_img\n\n"
                "2) Add ASR transcripts before training."
            )
            root.destroy()

            return {"ok": True}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def delete_video(self):
        try:
            p = self.last_local_path
            if not p:
                return {"ok": False, "msg": "No file recorded in session"}
            if os.path.exists(p):
                os.remove(p)
                self.last_local_path = None
                return {"ok": True}
            return {"ok": False, "msg": "File not found"}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

    def open_external(self):
        try:
            p = self.last_local_path
            if not p or not os.path.exists(p):
                return {"ok": False, "msg": "File not found"}
            system = platform.system()
            if system == "Darwin":
                subprocess.Popen(["open", p])
            elif system == "Windows":
                subprocess.Popen(["start", "", p], shell=True)
            else:
                subprocess.Popen(["xdg-open", p])
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "msg": str(e)}

# ---------------- main ---------------- #
def main():
    _ensure_dir(DOWNLOAD_DIR)

    # Start local HTTP server
    server = LocalServer(DOWNLOAD_DIR)
    server.start()

    # Inject default CSV path
    html = HTML_TEMPLATE.replace('id="csv" type="text" />', f'id="csv" type="text" value="{CSV_DEFAULT}" />')

    bridge = Bridge(server)
    window = webview.create_window("Add New Video", html=html, width=980, height=780, js_api=bridge)
    try:
        webview.start()
    finally:
        server.stop()

if __name__ == "__main__":
    main()