# -*- coding: utf-8 -*-
# Python 3.8

import argparse
import csv
import json
import os
import re
from typing import Dict, List, Optional, Tuple

# 경로 패턴들
RE_UNORDERED = re.compile(r"(?:^|/)unordered/([^/]+)/")  # .../unordered/<video_id>/
RE_NUMERIC = re.compile(r"^\d+$")
RE_TRANS = re.compile(r"^([A-Za-z0-9_\-]+)_transcripts\.csv$")

def map_saved_dir_to_lecture_dir(saved_dir: str, data_root: str) -> Optional[str]:
    """
    saved_dir (예: data/anat-1/AnatomyPhysiology/26/slide_013.jpg)를
    data_root 기반의 실제 강의 디렉토리(예: data_oct/anat-1/AnatomyPhysiology/26)로 변환.
    """
    saved_dir = os.path.normpath(saved_dir)
    parts = saved_dir.split(os.sep)
    if len(parts) < 3:
        return None

    # 'data' 또는 'data_oct' 루트 위치 찾기
    try:
        i = parts.index("data")
    except ValueError:
        try:
            i = parts.index("data_oct")
        except ValueError:
            return None

    # 파일명 제거하고, 루트('data' 또는 'data_oct')를 data_root로 치환
    dir_parts = parts[i+1:-1]  # speaker / 중간폴더들 / lecture_num
    lecture_dir = os.path.join(data_root, *dir_parts) if dir_parts else data_root
    return lecture_dir

def load_csv_rows(path: str) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    with open(path, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
    return rows

def parse_bboxes(raw: str) -> List[Dict]:
    """
    boundingBoxes 필드를 JSON으로 파싱.
    CSV 안에서 이스케이프된 경우가 있어 기본 로드 실패 시 보정 후 재시도.
    """
    if raw is None:
        return []
    s = raw.strip()
    if not s or s == "[]":
        return []
    try:
        return json.loads(s)
    except Exception:
        try:
            # CSV에서 내부 따옴표가 ""로 중복된 경우 보정
            s2 = s.replace('""', '"')
            return json.loads(s2)
        except Exception:
            return []

def replace_ext_to_png(path: str) -> str:
    base = os.path.basename(path)
    name, _ = os.path.splitext(base)
    return f"{name}.png"

def extract_video_id_from_unordered(saved_dir: str) -> Optional[str]:
    m = RE_UNORDERED.search(saved_dir)
    return m.group(1) if m else None

def find_video_id_from_lecture_dir(data_root: str, speaker: str, lecture_num: str) -> Optional[str]:
    """
    (백업용) data_root/<speaker> 아래를 재귀로 돌며 lecture_num 디렉토리를 찾아
    그 안의 *_transcripts.csv 파일명에서 video_id를 추출.
    """
    speaker_root = os.path.join(data_root, speaker)
    if not os.path.isdir(speaker_root):
        return None

    for dirpath, _, files in os.walk(speaker_root):
        # 디렉토리명이 lecture_num인지 확인
        if os.path.basename(dirpath) == lecture_num:
            for name in files:
                m = RE_TRANS.match(name)
                if m:
                    return m.group(1)
    return None

def guess_speaker_and_lectnum_from_path(saved_dir: str) -> Tuple[Optional[str], Optional[str]]:
    """
    saved_dir 예:
      data/anat-1/AnatomyPhysiology/26/slide_013.jpg
      data/bio-4/unordered/MoQWPwzTzFE/slide_025.jpg
    speaker는 첫 토큰 뒤(보통 'data' 또는 'data_oct' 다음)로 가정.
    lecture_num은 파일 바로 상위 또는 그 상위 디렉토리 중 숫자 디렉토리.
    """
    parts = saved_dir.strip("/").split("/")
    if len(parts) < 2:
        return None, None

    # 'data' 또는 'data_oct' 다음을 speaker로 가정
    if parts[0] in ("data", "data_oct"):
        if len(parts) >= 2:
            speaker = parts[1]
            # 뒤에서부터 숫자 디렉토리 하나를 찾음
            for p in reversed(parts[:-1]):  # 파일명 제외
                if RE_NUMERIC.match(p):
                    return speaker, p
            return speaker, None
        return None, None
    else:
        # 맨 앞이 data 계열이 아니면 두 번째를 speaker로 추정
        speaker = parts[1] if len(parts) > 1 else None
        # 숫자 디렉토리 탐색
        for p in reversed(parts[:-1]):
            if RE_NUMERIC.match(p):
                return speaker, p
        return speaker, None

def reconstruct_bbox(annotations_csv: str, data_root: str, out_json: str, unresolved_report: str) -> None:
    rows = load_csv_rows(annotations_csv)

    results: List[Dict] = []
    unresolved: List[Dict] = []

    for i, r in enumerate(rows):
        saved_dir = (r.get("Input.save_dir") or r.get("save_dir") or "").strip()
        bbox_raw = r.get("boundingBoxes")
        ocr_text = r.get("ocr")  # 사용하진 않지만, 필요시 참고용

        if not saved_dir:
            unresolved.append({"row_index": i, "reason": "missing save_dir", "row": r})
            continue

        # 1) unordered 경로면 경로에서 바로 video_id 추출
        video_id = extract_video_id_from_unordered(saved_dir)

        # 2) 아니면 speaker/lecture_num 추정 후 data_root에서 transcripts로 video_id 탐색
        if not video_id:
            speaker, lecture_num = guess_speaker_and_lectnum_from_path(saved_dir)
            if speaker and lecture_num:
                video_id = find_video_id_from_lecture_dir(data_root, speaker, lecture_num)

        # 3) 여전히 못 찾으면 unresolved로 보냄
        if not video_id:
            unresolved.append({"row_index": i, "reason": "video_id_not_found", "save_dir": saved_dir})
            continue

        # 4) boundingBoxes 파싱
        boxes = parse_bboxes(bbox_raw)
        if not boxes:
            # bbox가 아예 없으면 스킵 (요청: 더미 넣지 말기)
            continue

        # 5) slide 파일명(.png로 치환)
        slide_png = replace_ext_to_png(saved_dir)

        # 6) 각 bbox를 결과에 추가
        for b in boxes:
            try:
                label = b.get("label", "")
                x = int(b.get("left"))
                y = int(b.get("top"))
                w = int(b.get("width"))
                h = int(b.get("height"))
                results.append({
                    "video_id": video_id,
                    "slide": os.path.basename(slide_png),
                    "label": label,
                    "bbox": [x, y, w, h]
                })
            except Exception:
                # 필수 키가 없거나 숫자화 실패 시 해당 박스만 무시
                unresolved.append({
                    "row_index": i,
                    "reason": "invalid_bbox_entry",
                    "save_dir": saved_dir,
                    "bbox_entry": b
                })

    # 출력 디렉토리 보장
    out_dir = os.path.dirname(out_json) or "."
    os.makedirs(out_dir, exist_ok=True)

    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    with open(unresolved_report, "w", encoding="utf-8") as f:
        json.dump(unresolved, f, ensure_ascii=False, indent=2)

    print("=== reconstruct_bbox DONE ===")
    print(f"Output JSON          : {out_json}  (entries: {len(results)})")
    print(f"Unresolved Report    : {unresolved_report}  (items: {len(unresolved)})")

def main():
    parser = argparse.ArgumentParser(description="Reconstruct figure bbox JSON from noisy annotations CSV.")
    parser.add_argument("--annotations-csv", default="data_oct/figure_annotations.csv",
                        help="Path to figure_annotations.csv (default: data_oct/figure_annotations.csv)")
    parser.add_argument("--data-root", default="data_oct",
                        help="Root to search transcripts for video_id (default: data_oct)")
    parser.add_argument("--out-json", default="slide_img/figure_bbox.json",
                        help="Output JSON path (default: slide_img/figure_bbox.json)")
    parser.add_argument("--unresolved-report", default="slide_img/figure_bbox_unresolved.json",
                        help="Where to write unresolved items (default: slide_img/figure_bbox_unresolved.json)")
    args = parser.parse_args()

    reconstruct_bbox(
        annotations_csv=args.annotations_csv,
        data_root=args.data_root,
        out_json=args.out_json,
        unresolved_report=args.unresolved_report
    )

if __name__ == "__main__":
    main()