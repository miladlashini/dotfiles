#!/bin/bash

SRC_DIR="$1"

if [[ -z "$SRC_DIR" ]]; then
    echo "Usage: $0 <source_dir>"
    exit 1
fi

find "$SRC_DIR" -maxdepth 1 -type f -print0 |
while IFS= read -r -d '' file; do
    # Get modification time (epoch)
    mtime=$(stat -c %Y "$file")

    # Convert to YYYY-MM
    month=$(date -d @"$mtime" +%Y-%m)

    # Create month directory
    mkdir -p "$SRC_DIR/$month"

    # Move file
    mv "$file" "$SRC_DIR/$month/"
done
echo "Files have been organized by modification month in $SRC_DIR."
