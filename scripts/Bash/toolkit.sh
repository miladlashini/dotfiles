#!/bin/bash
#With this script we just want to present the user with a menu where they can
#choose which of the two scripts they want to run and then have this script run the
#relevant script based on the user’s selection
PS3="Please select the script you want to run: "
options=("Folder Organiser" "Cruft Remover" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "Folder Organiser")
            ./folder_organiser.sh
            ;;
        "Cruft Remover")
            ./cruft_remover.sh
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done