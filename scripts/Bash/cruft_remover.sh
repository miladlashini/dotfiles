#!/bin/bash
#/home/viserion/dotfiles/

# This script identifies and lists files in a specified folder that have been inactive for a certain number of days.

read -p "What is the folder you want to remove cruft from?: " folder
read -p "How may days should be the file inactive to be considered as cruft: " days

readarray -t cruft_files < <(find "$folder" -type f -mtime +"$days")

echo "The following files have been inactive for more than $days days:"

for file in "${cruft_files[@]}"; do
    echo "$file"
    # -exec rm -i "$file";
done



exit 0