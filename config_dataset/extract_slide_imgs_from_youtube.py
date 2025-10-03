# -*- coding: utf-8 -*-
# Python 3.8 OK
"""
CSV만 읽어 YouTube에서 직접 시킹하여 각 타임스탬프 프레임을 추출합니다.
(패치 버전) 네트워크 불안정/서명 URL 만료에 대비해:
  1) 비디오를 먼저 로컬로 '견고하게' 다운로드(재시도+검증)
  2) 로컬 mp4에서 프레임 추출(실패 시 ±jitter로 재시도)

- 의존성: yt-dlp, ffmpeg, ffprobe (PATH에 있어야 함)
- 출력 구조: ./slide_img/<video_id(normalized)>/slide_000.png ...
  (※ 파일명 인덱스는 CSV의 원래 타임스탬프 순서를 보존. -1은 스킵하되 인덱스는 유지)

사용 예:
  python3 extract_slide_imgs_from_youtube.py \
      --csv data_oct/raw_video_links.csv \
      --outdir slide_img \
      --download-dir ./.cache_ytdlp \
      --precise
"""

import os
import re
import sys
import argparse
import subprocess
from pathlib import Path
from typing import List, Optional, Tuple

import pandas as pd

# ---- 유틸 ----
YT_ID_RE = re.compile(r"[A-Za-z0-9_\-]{6,}")

EXPECTED_COLS = [
    "Answer.startTimeList", "seconds", "speaker", "video_id", "youtube_url", "learning_objectives"
]

def run(cmd: list) -> str:
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            "Command failed: {}\nSTDERR:\n{}".format(" ".join(cmd), proc.stderr)
        )
    return proc.stdout.strip()

def call_retcode(cmd: list) -> int:
    return subprocess.call(cmd)

def normalize_video_id(v: str) -> str:
    """
    CSV video_id: '_Jw3DQ7_pxg.mp4' -> 'Jw3DQ7_pxg'
    """
    v = str(v or "").strip()
    if v.endswith(".mp4"):
        v = v[:-4]
    while v and v[0] in "_-":
        v = v[1:]
    return v

# --- 타임스탬프 파싱: 기존 로직 유지 ---
def parse_start_times(s: str) -> List[float]:
    """'Start Time|91.2|224.0|...' -> [91.2, 224.0, ...]  (-1은 들어올 수 있음)"""
    if not isinstance(s, str):
        s = str(s)
    parts = [p for p in s.split("|") if p and "Start Time" not in p]
    out: List[float] = []
    for p in parts:
        p = p.strip().strip(",")
        try:
            out.append(float(p))
        except Exception:
            pass
    return out

# --- 새로 추가: 로컬 다운로드 & 검증 & 추출 ---

def probe_ok(path: Path) -> bool:
    if not path.exists() or path.stat().st_size < 1_000:  # 1KB 미만은 손상 취급
        return False
    try:
        # ffprobe로 duration/format 점검
        cmd = [
            "ffprobe", "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=nw=1:nk=1",
            str(path),
        ]
        out = run(cmd).strip()
        dur = float(out)
        return dur > 1.0  # 1초 초과만 정상으로 간주
    except Exception:
        return False

def download_video(youtube_url: str,
                   out_dir: Path,
                   vid_id: str,
                   fmt: str,
                   cookies: Optional[str],
                   max_retries: int = 3) -> Optional[Path]:
    """
    yt-dlp로 비디오(mp4)만 다운로드. 성공 시 파일 경로 반환, 실패 시 None.
    aria2c 멀티 커넥션 사용 가능(설치되어 있으면).
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    # 최종 저장 경로(확장자는 yt-dlp가 정하지만 mp4 우선 포맷을 요청)
    # -o 패턴을 명시적으로 id.ext 형태로 고정
    out_tmpl = str(out_dir / f"{vid_id}.%(ext)s")

    base_cmd = ["yt-dlp",
                "--force-ipv4",
                "-N", "8",
                "--retries", "infinite",
                "--fragment-retries", "100",
                "-f", fmt,
                "-o", out_tmpl]

    # aria2c가 있으면 병렬 다운 활용(없어도 yt-dlp가 자체 다운로드 수행)
    base_cmd += ["--downloader", "aria2c",
                 "--downloader-args", "aria2c:-x16 -k1M -m 0 --retry-wait=2 --max-tries=0 --console-log-level=warn"]

    if cookies:
        base_cmd.insert(1, f"--cookies={cookies}")

    last_exc = None
    for attempt in range(1, max_retries + 1):
        try:
            print(f"[DL ] {vid_id} attempt {attempt}/{max_retries}")
            # 이미 정상 파일이 있으면 재다운로드 생략
            candidate_mp4 = out_dir / f"{vid_id}.mp4"
            if candidate_mp4.exists() and probe_ok(candidate_mp4):
                print(f"[OK ] cache hit: {candidate_mp4}")
                return candidate_mp4

            # 다운로드 시도
            cmd = list(base_cmd) + [youtube_url]
            _ = run(cmd)

            # 확장자 결정: mp4 선호, 없으면 가장 최근 생성 파일 검색
            if candidate_mp4.exists():
                fpath = candidate_mp4
            else:
                # 확장자 추정
                found = list(out_dir.glob(f"{vid_id}.*"))
                fpath = found[0] if found else None

            if fpath and probe_ok(fpath):
                print(f"[OK ] downloaded: {fpath}")
                return fpath
            else:
                # 불량 파일은 삭제하고 재시도
                if fpath and fpath.exists():
                    try:
                        fpath.unlink()
                    except Exception:
                        pass
                print(f"[WARN] probe failed; retrying...")
        except Exception as e:
            last_exc = e
            print(f"[ERR ] download error: {e}; retrying...")

    print(f"[FATL] download failed for {vid_id}: {last_exc}")
    return None

def extract_frame_local(video_path: Path,
                        t_seconds: float,
                        out_path: Path,
                        precise: bool,
                        retries: int = 3,
                        jitter: float = 0.2) -> bool:
    """
    로컬 mp4에서 프레임 추출. 실패 시 ±jitter로 재시도.
    """
    out_path.parent.mkdir(parents=True, exist_ok=True)

    def try_once(ts: float) -> bool:
        if precise:
            cmd = [
                "ffmpeg", "-hide_banner", "-loglevel", "error",
                "-i", str(video_path),
                "-ss", f"{ts:.3f}",
                "-frames:v", "1",
                "-q:v", "2",
                "-y", str(out_path),
            ]
        else:
            cmd = [
                "ffmpeg", "-hide_banner", "-loglevel", "error",
                "-ss", f"{ts:.3f}",
                "-i", str(video_path),
                "-frames:v", "1",
                "-q:v", "2",
                "-y", str(out_path),
            ]
        code = call_retcode(cmd)
        return (code == 0) and out_path.exists()

    # 1차 시도
    if try_once(t_seconds):
        print(f"[OK ] {t_seconds:.3f}s -> {out_path}")
        return True

    # 재시도: t±jitter
    for k in range(1, retries + 1):
        for sign in (-1, 1):
            ts = max(0.0, t_seconds + sign * jitter * k)
            if try_once(ts):
                print(f"[OK ] {t_seconds:.3f}s (retry@{ts:.3f}) -> {out_path}")
                return True

    print(f"[ERR] {t_seconds:.3f}s -> {out_path}")
    return False

# ---- 메인 ----
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="raw_video_links.csv 경로 (또는 left_video_links.csv)")
    ap.add_argument("--outdir", default="slide_img", help="출력 루트 디렉토리")
    ap.add_argument("--download-dir", default="./.cache_ytdlp", help="비디오 다운로드 캐시 디렉토리")
    ap.add_argument("--cookies", default=None, help="cookies.txt 경로 (선택)")
    ap.add_argument("--format", default="bv*[ext=mp4]/bv*", help="yt-dlp 포맷 선택자")
    ap.add_argument("--precise", action="store_true", help="정확 시킹(느림)")
    ap.add_argument("--only-first", action="store_true", help="각 영상 첫 유효 타임스탬프만 추출(원래 인덱스 보존)")
    ap.add_argument("--keep-existing", action="store_true", help="동일 파일명 존재 시 추출 스킵")
    ap.add_argument("--max-download-retries", type=int, default=3, help="비디오 다운로드 최대 재시도(기본 3)")
    ap.add_argument("--extract-retries", type=int, default=3, help="프레임 추출 재시도 횟수(기본 3)")
    ap.add_argument("--jitter", type=float, default=0.2, help="재시도 시 ±초 단위 지터(기본 0.2)")
    args = ap.parse_args()

    out_root = Path(args.outdir)
    out_root.mkdir(parents=True, exist_ok=True)
    dl_root = Path(args.download_dir)

    # 1) CSV 로드 및 컬럼 검증
    try:
        df = pd.read_csv(args.csv)
    except Exception as e:
        print(f"[FATAL] CSV 로드 실패: {e}")
        sys.exit(1)

    missing = [c for c in EXPECTED_COLS if c not in df.columns]
    if missing:
        print(f"[FATAL] CSV missing columns: {missing}. Found: {list(df.columns)}")
        sys.exit(1)

    # 2) 전 행 순회 (speaker 필터 없이 video_id 별 처리)
    total_videos = 0
    successful_videos = 0
    total_frames_requested = 0   # 시도 대상(>=0) 프레임 수
    total_frames_saved = 0

    # video_id 기준으로 그룹핑(같은 영상이 여러 행에 나뉘어 있을 수도 있음)
    df["_norm_id"] = df["video_id"].apply(normalize_video_id)
    grouped = df.groupby("_norm_id", dropna=False)

    for norm_id, g in grouped:
        if not isinstance(norm_id, str) or not norm_id:
            continue

        youtube_urls = [u for u in g["youtube_url"].astype(str).tolist() if u and u != "nan"]
        if not youtube_urls:
            print(f"[MISS] video_id='{norm_id}' 의 youtube_url 없음 → 스킵")
            continue
        youtube_url = youtube_urls[0]

        # CSV 등장 순서대로 타임스탬프 (행 내부 인덱스 k를 파일명에 사용)
        raw_pairs: List[Tuple[int, float]] = []
        for _, row in g.iterrows():
            ts = parse_start_times(row["Answer.startTimeList"])
            if not ts:
                try:
                    sec = float(row.get("seconds", 1.0))
                except Exception:
                    sec = 1.0
                ts = [max(0.0, sec - 1.0)]
            for k, t in enumerate(ts):
                raw_pairs.append((k, t))

        # 유효 타임스탬프만
        valid_pairs: List[Tuple[int, float]] = [(k, t) for (k, t) in raw_pairs if isinstance(t, (int, float)) and t >= 0]
        if not valid_pairs:
            continue

        total_videos += 1
        if args.only_first:
            valid_pairs = [valid_pairs[0]]
        total_frames_requested += len(valid_pairs)

        # --- 로컬 다운로드 & 검증 ---
        video_path = download_video(
            youtube_url=youtube_url,
            out_dir=dl_root,
            vid_id=norm_id,
            fmt=args.format,
            cookies=args.cookies,
            max_retries=args.max_download_retries,
        )
        if not video_path:
            print(f"[ERR ] download failed, skip video_id='{norm_id}'")
            continue

        vid_out_dir = out_root / norm_id
        saved_count = 0

        # --- 로컬에서 프레임 추출 ---
        for k, t in valid_pairs:
            out_path = vid_out_dir / f"slide_{k:03d}.png"
            if args.keep_existing and out_path.exists():
                print(f"[SKIP] exists -> {out_path}")
                total_frames_saved += 1
                saved_count += 1
                continue

            ok = extract_frame_local(
                video_path=video_path,
                t_seconds=t,
                out_path=out_path,
                precise=args.precise,
                retries=args.extract_retries,
                jitter=args.jitter,
            )
            if ok:
                saved_count += 1
                total_frames_saved += 1

        if saved_count > 0:
            successful_videos += 1

        print(f"[STAT] video_id='{norm_id}': saved {saved_count}/{len(valid_pairs)} frames")

    # 3) 최종 통계
    success_ratio = (successful_videos / total_videos * 100.0) if total_videos else 0.0
    print("\n=== SUMMARY ===")
    print(f"Videos processed:   {total_videos}")
    print(f"Videos succeeded:   {successful_videos} ({success_ratio:.2f}%)")
    print(f"Frames requested:   {total_frames_requested}")
    print(f"Frames saved:       {total_frames_saved}")

if __name__ == "__main__":
    main()