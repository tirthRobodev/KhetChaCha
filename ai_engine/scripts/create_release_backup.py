"""Creates a clean, production-grade backup zip of the KhetChacha project."""

import os
import sys
import zipfile
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT_DIR = Path("D:/KhetChaCha")
BACKUP_DIR = ROOT_DIR / "backups"
BACKUP_ZIP = BACKUP_DIR / "khetchacha_release_baseline_20261104.zip"

EXCLUDE_DIRS = {
    ".venv",
    "__pycache__",
    ".dart_tool",
    "build",
    ".pytest_cache",
    ".git",
    "government_schemes_extracted",
    "backups",
}

EXCLUDE_FILES = {
    ".env",
    "finalsceme.zip",
}

INCLUDE_DIRS = [
    "lib",
    "test",
    "assets",
    "ai_engine",
    "data",
    "android",
    "ios",
    "linux",
    "macos",
    "web",
    "windows",
]

INCLUDE_ROOT_FILES = [
    "pubspec.yaml",
    "pubspec.lock",
    "README.md",
    "analysis_options.yaml",
]

def make_backup():
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Creating backup at {BACKUP_ZIP}...")
    total_files = 0
    total_bytes = 0

    with zipfile.ZipFile(BACKUP_ZIP, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        # Include root files
        for fname in INCLUDE_ROOT_FILES:
            fp = ROOT_DIR / fname
            if fp.exists():
                zf.write(fp, arcname=fname)
                total_files += 1
                total_bytes += fp.stat().st_size

        # Include root directories
        for dname in INCLUDE_DIRS:
            dp = ROOT_DIR / dname
            if not dp.exists():
                continue
            for root, dirs, files in os.walk(dp):
                # Filter out excluded directories in-place
                dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith(".")]
                for f in files:
                    if f in EXCLUDE_FILES or f.endswith(".pyc") or f.endswith(".log"):
                        continue
                    full_p = Path(root) / f
                    arc_p = full_p.relative_to(ROOT_DIR)
                    zf.write(full_p, arcname=str(arc_p))
                    total_files += 1
                    total_bytes += full_p.stat().st_size

        # Ensure .env is never included, .env.example on disk is included automatically

    zip_size_mb = BACKUP_ZIP.stat().st_size / (1024 * 1024)
    raw_size_mb = total_bytes / (1024 * 1024)
    print(f"Backup complete!")
    print(f"  Files archived: {total_files}")
    print(f"  Uncompressed size: {raw_size_mb:.2f} MB")
    print(f"  Compressed ZIP size: {zip_size_mb:.2f} MB")
    print(f"  Archive location: {BACKUP_ZIP}")

if __name__ == "__main__":
    make_backup()
