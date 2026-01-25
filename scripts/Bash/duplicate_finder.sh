#!/usr/bin/env bash
# -e If any command exits with a non-zero status, the script exits immediately. could be problematic for example with grep that finds nothing.
# -u treat unset variables as errors
# -o pipefail — fail if any part of a pipeline fails (Manzoor hamoon pipe kardan be hame command ha)
set -euo pipefail

SEARCH_DIR="${1:-}"
OUTPUT_FILE="${2:-duplicates.txt}"

if [[ -z "$SEARCH_DIR" || ! -d "$SEARCH_DIR" ]]; then
    echo "Usage: $0 <directory> [output_file]"
    exit 1
fi

# Choose hash function (fast + reliable)
# HASH_CMD="sha256sum"
# For faster but slightly weaker hash, use:
HASH_CMD="xxh64sum"

declare -A size_groups
declare -A hash_groups

# Clear output file
: > "$OUTPUT_FILE"

echo "Scanning files and grouping by size..." | tee -a "$OUTPUT_FILE"

# raw input (no backslash escaping)

# 1. Collect files and group by size
while IFS= read -r -d '' file; do
    size=$(stat -c %s "$file")
    size_groups["$size"]+=$'\n'"$file"
# print0 Prints each found pathname followed by a NUL byte (\0) instead of a newline.
done < <(find "$SEARCH_DIR" -type f -print0)

echo "Hashing files with matching sizes..." | tee -a "$OUTPUT_FILE"

# <<< is a here-string. It feeds the contents of a variable as stdin to a command

# 2. Hash only files with same size
for size in "${!size_groups[@]}"; do
    files="${size_groups[$size]}"

    # Skip sizes with only one file
    # “Count how many non-empty lines are in $files.” -c — count matching lines . (dot) matches any single character
    if [[ $(grep -c . <<< "$files") -lt 2 ]]; then
        continue
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        hash=$($HASH_CMD "$file" | awk '{print $1}')
        hash_groups["$hash"]+=$'\n'"$file"
    done <<< "$files"
done

echo | tee -a "$OUTPUT_FILE"
echo "Duplicate files (same hash):" | tee -a "$OUTPUT_FILE"
echo "--------------------------------" | tee -a "$OUTPUT_FILE"

found=false

# ${!hash_groups[@]} expands to the list of keys (indexes) of the associative array hash_groups.

# 3. Print duplicates
for hash in "${!hash_groups[@]}"; do
    files="${hash_groups[$hash]}"
    count=$(grep -c . <<< "$files")

    if [[ "$count" -gt 1 ]]; then
        found=true
        {
            echo
            echo "Hash: $hash"
            echo "$files"
        } | tee -a "$OUTPUT_FILE"
    fi
done

if ! $found; then
    echo "No duplicate files found."
fi
