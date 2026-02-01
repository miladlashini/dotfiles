#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <extension> <source_dir> <destination_dir>"
  echo "Example: $0 jpg /path/to/src /path/to/dst"
  exit 1
fi

ext="$1"
src="$2"
dst="$3"

# Remove leading dot if user provides ".jpg"
ext="${ext#.}"

# Sanity checks
if [ ! -d "$src" ]; then
  echo "Source directory does not exist: $src"
  exit 1
fi

mkdir -p "$dst"
# Enable nullglob to handle no matches gracefully
# If a glob matches nothing, it expands to nothing (empty).
# other wise glob returns the pattern itself.
shopt -s nullglob

files=("$src"/*."$ext")

if [ "${#files[@]}" -eq 0 ]; then
  echo "No .$ext files found in $src"
  exit 0
fi
# In mv, -- means “end of options”. It allows for filenames that 
# begin with a hyphen (-) to be correctly interpreted as filenames rather than options.
# works with other commands too like cp, rm, etc.
mv -- "${files[@]}" "$dst"

echo "Moved ${#files[@]} .$ext file(s) from $src to $dst"
