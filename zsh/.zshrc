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
# oh-my-zsh is loaded through antigen ("antigen use oh-my-zsh" in
# .antigenrc) rather than sourced directly. Its usual tunables (ZSH_THEME,
# plugins=(...), CASE_SENSITIVE, HIST_STAMPS, ... - see
# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes) still apply if set above
# "antigen init" below, but this setup manages the theme/plugin list through
# .antigenrc's "antigen bundle"/"antigen theme" lines instead.

if [[ ! -d "${ADOTDIR:?Missing mandatory env}" ]]; then
    # Resolve antigen's latest release tag via the /releases/latest redirect
    # (no GitHub API call, so it isn't subject to the API's unauthenticated
    # rate limit). Falls back to a known-good pin if that fails (e.g. no
    # network yet on a brand new machine). Only runs on this one-time
    # bootstrap clone, never on every shell startup.
    _antigen_version="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
        https://github.com/zsh-users/antigen/releases/latest 2>/dev/null)"
    _antigen_version="${_antigen_version##*/}"
    [[ "$_antigen_version" == v[0-9]* ]] || _antigen_version="v2.2.3"

    git clone \
        --depth 1 \
        -b "$_antigen_version" \
        "https://github.com/zsh-users/antigen.git" \
        "${ADOTDIR}"
    unset _antigen_version
fi
source "${ADOTDIR}/antigen.zsh"

# Reads $ZDOTDIR/.antigenrc (bundle/theme list) and applies it.
antigen init "${ZDOTDIR}/.antigenrc"

# Must come after antigen init - zsh-autosuggestions/zsh-syntax-highlighting
# set their own defaults for these arrays when they're sourced, which would
# clobber a value assigned any earlier.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_HIGHLIGHT_STYLES[comment]='fg=240,bold'

########################################
# personal config files
########################################
for _f in "${ZDOTDIR}/aliases" "${ZDOTDIR}/yocto"; do
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
# unlimited core dump size - see aliases: coreDumpStatus / activateCoreDump*
ulimit -c unlimited

########################################
# functions
########################################

# quick internet reachability check
online() {
    if ping -c 1 google.com &>/dev/null; then
        echo "Online!"
    else
        echo "Offline"
    fi
}

# navigate the filesystem graphically via ranger, cd-ing into the chosen dir on exit
goto() {
    local tempfile
    tempfile=$(mktemp)
    ranger --choosedir="$tempfile" "${@:-$PWD}"
    if [ -f "$tempfile" ] && [ -s "$tempfile" ]; then
        cd "$(cat "$tempfile")"
    fi
    rm -f "$tempfile"
}

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
