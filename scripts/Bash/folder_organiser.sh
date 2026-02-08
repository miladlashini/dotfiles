#!/bin/bash

# construct a while loop that will iterate over the output of the ls command.
read -p "Enter the directory to organise: " target_dir

if [[ ! -d "$target_dir" ]]; then
    echo "Directory does not exist."
    exit 1
fi
# By setting IFS to empty: “Do not split the input line on spaces, tabs, or newlines.”
while IFS= read -r file; do  # -r : “Do not treat backslashes as escape characters.”
    #check if it is a file
    if [[ -f "$target_dir/$file" ]]; then
        # get the file extension
        # ${variable##pattern}
        # ## means:
        # remove the longest match of pattern from the beginning
        # *. means:
        # “anything up to the last dot”
        extension="${file##*.}"
        case "$extension" in
            "txt"|"md"|"doc"|"docx") extension="documents" ;;
            "jpg"|"jpeg"|"png"|"gif"|"bmp") extension="images" ;;
            "mp4"|"mkv"|"avi"|"mov") extension="videos" ;;
            "mp3"|"wav"|"flac") extension="audio" ;;
            "pdf") extension="pdfs" ;;
            *) extension="others" ;;
        esac
        # create a directory for the extension if it doesn't exist
        mkdir -p "$target_dir/$extension"
        # move the file to the corresponding directory
        mv "$target_dir/$file" "$target_dir/$extension/"
        echo "Moved $file to $extension/"
    fi
done < <(ls "$target_dir")