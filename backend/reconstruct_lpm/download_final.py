#!/usr/bin/env python3
# Python 3.8
# Usage:
#   python download_final.py
#   python download_final.py --out dataset.tar.gz
#   python download_final.py --cookies cookies.txt
#   python download_final.py --url "https://drive.google.com/file/d/FILE_ID/view"
#
# Tip:
# - Link requires SNU login: ensure your browser is logged into your @snu.ac.kr account.
# - If still blocked, export cookies (cookies.txt) and pass --cookies.

import argparse
import os
import sys
import tarfile
import shutil
import tempfile
import time

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def ensure_gdown():
    try:
        import gdown  # noqa
        return True
    except ImportError:
        eprint("[INFO] 'gdown' not found. Attempting to install it: pip install gdown")
        try:
            import subprocess
            subprocess.check_call([sys.executable, "-m", "pip", "install", "gdown"])
            import gdown  # noqa
            return True
        except Exception as ex:
            eprint("[ERROR] Failed to install 'gdown'. Please install manually: pip install gdown")
            eprint(f"Reason: {ex}")
            return False

def human_warn():
    print("============================================================")
    print("  WARNING: Large download (dataset.tar.gz).")
    print("  - This may take a long time depending on your connection.")
    print("  - Make sure you have sufficient disk space.")
    print("  - If the file is restricted to SNU accounts,")
    print("    be logged into your @snu.ac.kr Google account.")
    print("============================================================")

def parse_args():
    parser = argparse.ArgumentParser(
        description="Download dataset.tar.gz from Google Drive (SNU login may be required)."
    )
    parser.add_argument(
        "--url",
        default="https://drive.google.com/file/d/1_o0zKLsUnEHqsRozHdt5UZkli-h2vs9R/view?usp=share_link",
        help="Google Drive file URL (view link or share link).",
    )
    parser.add_argument(
        "--out",
        default="dataset.tar.gz",
        help="Output file path (default: dataset.tar.gz)",
    )
    parser.add_argument(
        "--cookies",
        default=None,
        help="Path to cookies.txt (optional). Useful if file requires SNU login.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the existing output file if it already exists.",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=3,
        help="Number of download retries on failure (default: 3).",
    )
    return parser.parse_args()

def verify_tar_gz(path):
    # Quick integrity check by attempting to read the tar listing.
    try:
        with tarfile.open(path, "r:gz") as tf:
            # Just try to read first member; don't extract.
            for _ in tf:
                break
        return True
    except tarfile.ReadError:
        return False
    except Exception:
        return False

def main():
    args = parse_args()
    human_warn()

    if not ensure_gdown():
        sys.exit(1)

    # Safety: prevent accidental overwrite unless --force
    if os.path.exists(args.out) and not args.force:
        eprint(f"[INFO] Output already exists: {args.out}")
        eprint("       Use --force to overwrite, or remove the file and re-run.")
        sys.exit(0)

    # Prepare temp location to avoid partial file named as final output
    tmp_dir = tempfile.mkdtemp(prefix="gdown_tmp_")
    tmp_out = os.path.join(tmp_dir, "download.tmp")

    try:
        import gdown

        # gdown can parse both share/view URLs and direct IDs with fuzzy=True
        success = False
        last_error = None

        for attempt in range(1, args.retries + 1):
            try:
                eprint(f"[INFO] Download attempt {attempt}/{args.retries} ...")
                gdown.download(
                    url=args.url,
                    output=tmp_out,
                    quiet=False,
                    fuzzy=True,
                    use_cookies=True if args.cookies else False,
                    # gdown doesn't take a cookies path directly in Python API,
                    # but it reads cookies from ~/.config/gdown/cookies if present.
                )
                # If a cookies file is provided, inform the user how to use it
                if args.cookies:
                    eprint("[NOTE] You provided --cookies, but the Python API of gdown reads cookies")
                    eprint("       from its default location. If download failed due to auth,")
                    eprint("       try the CLI fallback below.")
                # Basic check: ensure file was created
                if os.path.getsize(tmp_out) == 0:
                    raise RuntimeError("Empty file downloaded.")
                success = True
                break
            except Exception as ex:
                last_error = ex
                eprint(f"[WARN] Download failed on attempt {attempt}: {ex}")
                # Small backoff before retry
                time.sleep(min(5 * attempt, 15))

        if not success:
            eprint("[ERROR] Download via Python API failed.")
            if args.cookies:
                eprint("CLI fallback with cookies:")
                eprint(f"  gdown '{args.url}' -O '{args.out}' --fuzzy --cookies '{args.cookies}'")
            else:
                eprint("Try:")
                eprint(f"  gdown '{args.url}' -O '{args.out}' --fuzzy")
                eprint("If the file requires SNU login, export cookies (cookies.txt) from your browser")
                eprint("and re-run with: --cookies /path/to/cookies.txt")
            if last_error:
                eprint(f"Last error: {last_error}")
            sys.exit(2)

        # Move temp file to final path
        if os.path.exists(args.out):
            if args.force:
                os.remove(args.out)
            else:
                eprint(f"[ERROR] Output file already exists: {args.out}. Use --force to overwrite.")
                sys.exit(3)
        shutil.move(tmp_out, args.out)
        eprint(f"[INFO] Downloaded to: {args.out}")

        # Quick integrity check for tar.gz
        eprint("[INFO] Verifying tar.gz integrity...")
        ok = verify_tar_gz(args.out)
        if ok:
            eprint("[INFO] Basic integrity check passed (tar.gz is readable).")
        else:
            eprint("[WARN] Integrity check failed. The file may be corrupted or not a valid tar.gz.")
            eprint("      Try re-downloading, or confirm access permissions.")

        print(args.out)

    finally:
        try:
            shutil.rmtree(tmp_dir)
        except Exception:
            pass

if __name__ == "__main__":
    main()