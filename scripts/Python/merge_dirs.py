#!/usr/bin/env python3

import shutil
import sys
from pathlib import Path

def unique_path(path: Path) -> Path:
    stem = path.stem
    suffix = path.suffix
    parent = path.parent
    i = 1

    while True:
        new_path = parent / f"{stem}_{i}{suffix}"
        if not new_path.exists():
            return new_path
        i += 1

def merge_dirs(src: Path, dst: Path):
    dst.mkdir(parents=True, exist_ok=True)

    for item in src.iterdir():
        target = dst / item.name

        if item.is_dir():
            if target.exists() and target.is_dir():
                merge_dirs(item, target)
            else:
                shutil.copytree(item, target)

        elif item.is_file():
            if target.exists():
                target = unique_path(target)
            shutil.copy2(item, target)

def main():
    if len(sys.argv) != 3:
        print("Usage: merge_dirs.py <destination_dir> <source_dir>")
        sys.exit(1)

    dst = Path(sys.argv[1]).resolve()
    src = Path(sys.argv[2]).resolve()

    if not dst.is_dir() or not src.is_dir():
        print("Both paths must be directories")
        sys.exit(1)

    merge_dirs(src, dst)

if __name__ == "__main__":
    main()
