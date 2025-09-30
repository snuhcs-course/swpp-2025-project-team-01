# Python 3.8 OK
# make_left_video_links.py
"""
raw_video_links.csv에서 '이미 저장된 슬라이드 이미지'에 대응하는 타임스탬프는 -1로 치환하고,
아직 저장되지 않은 타임스탬프는 그대로 두어 left_video_links.csv를 생성합니다.

추가:
- 만약 한 행의 모든 타임스탬프가 -1이면, 그 행은 CSV에서 제거합니다.
"""

import argparse
from pathlib import Path
import pandas as pd


def normalize_video_id(v: str) -> str:
    if v is None:
        return ""
    s = str(v).strip()
    if s.endswith(".mp4"):
        s = s[:-4]
    while s and s[0] in "_-":
        s = s[1:]
    return s


def parse_start_times(s: str):
    if not isinstance(s, str):
        s = str(s)
    parts = [p for p in s.split("|") if p and "Start Time" not in p]
    out = []
    for p in parts:
        p = p.strip().strip(",")
        try:
            out.append(float(p))
        except Exception:
            pass
    return out


def rebuild_start_time_field(times):
    return "Start Time|" + "|".join(str(t) for t in times)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="raw_video_links.csv 경로")
    ap.add_argument("--imgroot", default="slide_img", help="이미지 루트(예: slide_img)")
    ap.add_argument("--out", default="left_video_links.csv", help="출력 CSV 경로")
    args = ap.parse_args()

    csv_path = Path(args.csv)
    imgroot = Path(args.imgroot)
    out_path = Path(args.out)

    df = pd.read_csv(csv_path)
    if "video_id" not in df.columns:
        raise ValueError(f"'video_id' 컬럼이 없습니다. columns={list(df.columns)}")

    df["_norm_id"] = df["video_id"].map(normalize_video_id)

    total_ts_requested = 0
    total_ts_done = 0
    total_ts_remaining = 0
    removed_rows = 0

    out_rows = []

    for idx, row in df.iterrows():
        norm_id = str(row["_norm_id"])
        orig_times = parse_start_times(row.get("Answer.startTimeList", ""))

        if not orig_times:
            try:
                sec = float(row.get("seconds", 1.0))
            except Exception:
                sec = 1.0
            orig_times = [max(0.0, sec - 1.0)]

        new_times = []
        done = 0
        for k, t in enumerate(orig_times):
            slide_path = imgroot / norm_id / f"slide_{k:03d}.png"
            if slide_path.exists():
                new_times.append(-1)  # 성공한 timestamp는 -1로 치환
                done += 1
            else:
                new_times.append(t)

        req = len(orig_times)
        rem = req - done
        total_ts_requested += req
        total_ts_done += done
        total_ts_remaining += rem

        if rem == 0:
            # 모든 타임스탬프가 -1 → 행 제거
            removed_rows += 1
            print(f"[{norm_id}] all {req} done → 행 제거")
            continue

        print(f"[{norm_id}] remaining {rem}/{req} (done {done})")

        new_row = row.copy()
        new_row["Answer.startTimeList"] = rebuild_start_time_field(new_times)
        out_rows.append(new_row)

    out_df = pd.DataFrame(out_rows).drop(columns=["_norm_id"], errors="ignore")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_df.to_csv(out_path, index=False, encoding="utf-8")

    print("\n=== SUMMARY ===")
    print(f"Timestamps requested:   {total_ts_requested}")
    print(f"Timestamps already done:{total_ts_done}")
    print(f"Timestamps remaining:   {total_ts_remaining}")
    print(f"Rows removed (all -1) : {removed_rows}")
    print(f"[OK] 출력 CSV: {out_path}")


if __name__ == "__main__":
    main()