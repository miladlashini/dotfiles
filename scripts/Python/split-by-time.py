import os
import sys
import math
from pathlib import Path

if len(sys.argv) != 3:
    print("Usage: python split_by_time.py <source_dir> <n>")
    sys.exit(1)

src = Path(sys.argv[1])
n = int(sys.argv[2])

files = [f for f in src.iterdir() if f.is_file()]
files.sort(key=lambda f: f.stat().st_mtime)  # modification time

chunk_size = math.ceil(len(files) / n)

for i in range(n):
    target = src / f"chunk_{i+1}"
    target.mkdir(exist_ok=True)

    for f in files[i*chunk_size:(i+1)*chunk_size]:
        f.rename(target / f.name)
    print(f"Moved {len(files[i*chunk_size:(i+1)*chunk_size])} files to {target}")