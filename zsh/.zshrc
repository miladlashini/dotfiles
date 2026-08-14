#!/usr/bin/env zsh
#
# .zshrc - sourced by every INTERACTIVE zsh shell, after .zshenv. Owns the
# prompt, plugin manager, completion, aliases, and interactive keybindings;
# environment/PATH setup belongs in .zshenv instead (see that file).
#
# Symlinked to ~/.zshrc by ../install.sh. See .zshrc.legacy for the
# previous, unsectioned version of this file.

########################################
# Powerlevel10k prompt
########################################
# Instant prompt must stay near the top: initialization code that may
# require console input (password prompts, [y/n] confirmations, etc.) has
# to go above this block; everything else goes below it.
source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" 2>/dev/null || true

# To customize the prompt, run `p10k configure` or edit
# $DOTFILES/zsh/.p10k.zsh directly.
source "${DOTFILES}/zsh/.p10k.zsh" 2>/dev/null || true

########################################
# oh-my-zsh / antigen
########################################
# Plugin manager bootstrap (bundle list lives in .antigenrc). Sourced
# directly rather than through the aliases_files loop below, because that
# loop silences errors - a broken plugin manager must fail loudly, not
# leave you with a bare prompt and no explanation.
source "${ZDOTDIR}/antigen-setup"

########################################
# personal config files
########################################
aliases_files=(
    "${ZDOTDIR}/aliases"
    "${ZDOTDIR}/system-aliases"
    "${ZDOTDIR}/git-aliases"
    "${ZDOTDIR}/debug-aliases"
    "${ZDOTDIR}/network-aliases"
    "${ZDOTDIR}/tmux-aliases"
    "${ZDOTDIR}/rpc-build-aliases"
    "${ZDOTDIR}/yocto")

for _f in "${aliases_files[@]}"; do
    source "${_f}" 2>/dev/null || true
done

########################################
# completion
########################################
autoload -Uz compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -u
_comp_options+=(globdots)  # include hidden files

########################################
# fzf
########################################
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh

########################################
# shell behavior
########################################
# unlimited core dump size - the single place this is set (aliases has
# core_dump_status to inspect it and set_core_dump_pattern for the
# /proc/sys/kernel/core_pattern side)
ulimit -c unlimited

########################################
# keybindings
########################################
bindkey -r '^l'
bindkey -r '^g'
bindkey -s '^g' 'clear\n'

########################################
# misc
########################################
#neofetch --ascii_distro manjaro
#neofetch --ascii_distro ubuntu
#neofetch --ascii_distro archlinux
#neofetch --ascii_distro fedora
shuf -n 1 "$DOTFILES/neofetch_distros.txt" | xargs -I % sh -c 'neofetch --ascii_distro %'

#if [ -x /usr/games/cowsay -a -x /usr/games/fortune ]; then
#   fortune | cowsay -f $(ls /usr/share/cowsay/cows/ | shuf -n1)
#fi

########################################
# nvm (Node version manager)
########################################
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
