#!/bin/bash

SRC_DIR="$1"
N="$2"

if [[ -z "$SRC_DIR" || -z "$N" ]]; then
    echo "Usage: $0 <source_dir> <number_of_dirs>"
    exit 1
fi

mkdir -p "$SRC_DIR"/chunk_{1..$N}

# Get sorted file list by modification time
# %T@ → modification time as seconds since epoch (floating point)
# %p → file path
# awk '{print $2}' Extracts only the filename (second column).
# mapfile (aka readarray)
# Reads lines from standard input into an array variable

mapfile -t files < <(find "$SRC_DIR" -maxdepth 1 -type f -printf '%T@ %p\n' | sort -n | awk '{print $2}')

#< <( ... ) ← Process Substitution
# Runs command
# Exposes its output as a temporary file descriptor
# Lets another command read from it as if it were a file

total=${#files[@]}
per_dir=$(( (total + N - 1) / N ))

i=0
dir=1

for f in "${files[@]}"; do
    mv "$f" "$SRC_DIR/chunk_$dir/"
    ((i++))
    if (( i % per_dir == 0 && dir < N )); then
        ((dir++))
    fi
done
echo "Files distributed into $N directories."