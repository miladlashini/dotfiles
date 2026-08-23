#!/usr/bin/env zsh
#
# .zshenv - always sourced by zsh (login, interactive, non-interactive, and
# script invocations via `#!/usr/bin/env zsh`). Kept to environment/PATH
# setup only; prompts/aliases/plugins belong in .zshrc instead, since those
# would be wasted work in non-interactive shells.
#
# Symlinked to ~/.zshenv by ../install.sh. See .zshenv.legacy for the
# previous, unsectioned version of this file.

# Because this file is re-sourced by every nested shell (a new tmux pane, a
# script run with #!/usr/bin/env zsh, etc.), and each of those inherits an
# already-populated PATH from its parent, naive `PATH="dir:$PATH"` prepends
# accumulate duplicate entries with every level of nesting. `typeset -U`
# keeps the path array (kept in sync with $PATH by zsh) de-duplicated
# instead, so re-sourcing is a no-op rather than a leak.
# make the path array contain only unique entries; $path is kept in sync with $PATH
typeset -U path 

########################################
# XDG base directories
########################################
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

########################################
# dotfiles repo layout
########################################
export DOTFILES="$HOME/dotfiles"
export ZDOTDIR="$DOTFILES/zsh"
export ADOTDIR="$ZDOTDIR/.antigen"
export BASH_SCRIPT_DIR="$DOTFILES/scripts/Bash"
export PY_SCRIPT_DIR="$DOTFILES/scripts/Python"

# Constants shared with install.sh (Qt version/prefix, ccache size, ...) -
# see versions.sh for the single source of truth.
# shellcheck disable=SC1091
source "$DOTFILES/versions.sh"
export QT_VERSION QT_PREFIX   # CCACHE_MAXSIZE is exported in build-cache

########################################
# PATH
########################################
export CMAKE_INSTALL_PREFIX="/tmp/RPC"

# Listed highest-priority first; prepended as a block onto whatever PATH
# already existed when this file was sourced (kept in $path at the end).
#
# path is a zsh array that is kept in sync with $PATH, so we can use array syntax to
path=(
  "$HOME/.local/bin"            # pip --user installs
  "/snap/bin"
  "$QT_PREFIX/bin"
  "$HOME/go/bin"
  "$CMAKE_INSTALL_PREFIX/bin"
  "$CMAKE_INSTALL_PREFIX/examples"
  "/usr/lib/ccache"             # gcc/g++/cc symlinks that invoke ccache
  "$BASH_SCRIPT_DIR"
  "$PY_SCRIPT_DIR"
  $path
)

# ${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} avoids leaving a leading/trailing
# empty entry (which libc treats as "search the current directory") when
# LD_LIBRARY_PATH isn't already set.
# LD_LIBRARY_PATH or absolutely nothing, depending on whether the user has already set it in their environment. 
# if LD_LIBRARY_PATH is set, prepend the Qt library path to it; otherwise, subtitute LD_LIBRARY_PATH with an empty string. The reason to use  :+ operastor is to avoid having dangling : at the end of the path, which would cause the current directory to be searched for libraries.
export LD_LIBRARY_PATH="$QT_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="$QT_PREFIX"

########################################
# RPC project
########################################
export RPC_SOURCE_DIR="$HOME/Documents/RPC/src"
# Base path for host builds - rpc-build-aliases' _rpc_build derives the
# actual, per-compiler directory from this (${RPC_BUILD_DIR_ROOT}-gcc,
# ${RPC_BUILD_DIR_ROOT}-clang, ...), the same way RPC_BUILD_DIR_RPI already
# is a dedicated directory rather than sharing this one. Each compiler gets
# its own persistent directory so gcc and clang builds never contend for the
# same one - CMake cannot change an already-configured directory's compiler
# in place (see src/CMakeLists.txt's own guard against exactly that
# scenario), so sharing one directory across compilers meant whichever was
# configured first stuck around silently, regardless of which build_rpc_*
# alias you ran later.
export RPC_BUILD_DIR_ROOT="/opt/RPC-build"
# Default for anything reading $RPC_BUILD_DIR before a build_rpc_* alias has
# picked a compiler this session (matches the gcc-14 CC/CXX default below) -
# _rpc_build reassigns this on every call to match whichever compiler that
# call actually selected.
export RPC_BUILD_DIR="${RPC_BUILD_DIR_ROOT}-gcc"
export RPC_BUILD_DIR_RPI="/opt/RPC-build-rpi"
export RPC_CLANG_TIDY="clang-tidy-19"
# update this if DHCP ever reassigns the Pi 1 B+'s address
export RPC_PI_HOST="root@192.168.2.193"

########################################
# Compiler selection
########################################
# Alternatives kept for quick manual switching - uncomment the pair you want.
#export CC=clang-14
#export CXX=clang++-14

# Guarded: don't clobber the cross-compiler inside a Yocto cross-compile
# shell (bitbake devshell or an SDK environment-setup session) - both of
# those export PKG_CONFIG_SYSROOT_DIR themselves.
if [[ -z "$PKG_CONFIG_SYSROOT_DIR" ]]; then
    export CC=gcc-14
    export CXX=g++-14
fi

export CXXFLAGS="-fdiagnostics-color=always"

########################################
# Build caching / distributed compilation
########################################
# ccache + distcc settings (needs CCACHE_MAXSIZE from versions.sh above)
source "$ZDOTDIR/build-cache"

########################################
# Misc
########################################
# set to "all" to see every Boost.Test log line instead of just failures
export BOOST_TEST_LOG_LEVEL=error

########################################
# Tool init
########################################
# Guarded: this file doesn't exist until install.sh's Rust step has run, and
# .zshenv must not fail/abort a shell that's starting before that.
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
