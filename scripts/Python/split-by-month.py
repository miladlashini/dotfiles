import sys
from pathlib import Path
from datetime import datetime

if len(sys.argv) != 2:
    print("Usage: python split_by_month.py <source_dir>")
    sys.exit(1)

src = Path(sys.argv[1])

for f in src.iterdir():
    if not f.is_file():
        continue

    # Modification time
    mtime = f.stat().st_mtime
    month = datetime.fromtimestamp(mtime).strftime("%Y-%m")

    target = src / month
    target.mkdir(exist_ok=True)

    f.rename(target / f.name)
    print(f"Moved {f.name} to {target}")