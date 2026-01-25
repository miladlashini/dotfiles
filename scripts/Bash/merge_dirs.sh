#!/usr/bin/env bash

set -e

SRC="$2"
DST="$1"

if [[ ! -d "$SRC" || ! -d "$DST" ]]; then
    echo "Usage: $0 <destination_dir> <source_dir>"
    exit 1
fi

merge_dir() {
    local src="$1"
    local dst="$2"

    mkdir -p "$dst"

    for item in "$src"/*; do
        [ -e "$item" ] || continue

        # extracts the final component of a path, i.e. the file or directory name without its parent path.
        name=$(basename "$item")
        dst_item="$dst/$name"

        if [[ -d "$item" ]]; then
            if [[ -d "$dst_item" ]]; then
                merge_dir "$item" "$dst_item"
            else
            # If destination directory does not exist, copy the entire source directory
                cp -a "$item" "$dst_item"
            fi

        elif [[ -f "$item" ]]; then
            if [[ -e "$dst_item" ]]; then
                # Get file name without extension
                base="${name%.*}"
                # Get file extension
                ext="${name##*.}"
                # Handle case where there is no extension 
                # File without extension such as "file" will have base="file" and ext="file", so we set ext to empty
                # or name="README"
                # base="README"
                # ext="README"
                [[ "$base" == "$ext" ]] && ext=""
                i=1
                # Find a new file name that does not exist in the destination
                while true; do
                # Generate new file name with incremented suffix ${ext:+.$ext} ensures the dot is only added if ext is not empty
                    new_name="${base}_${i}${ext:+.$ext}"
                    [[ ! -e "$dst/$new_name" ]] && break
                    ((i++))
                done
                cp -a "$item" "$dst/$new_name"
            else
                cp -a "$item" "$dst_item"
            fi
        fi
    done
}

merge_dir "$SRC" "$DST"
