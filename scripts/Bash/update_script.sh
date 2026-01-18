#!/usr/bin/env bash

sudo apt -y update
sudo apt -y upgrade

if [[ -f /var/run/reboot-required ]]; then
    echo
    read -rp "A reboot is required. Reboot now? [y/N]: " answer
    # =~ is the regular-expression match operator, and it only works inside [[ ... ]].
    if [[ $answer =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Reboot cancelled."
    fi
fi
