
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
# for dotfiles
export XDG_CONFIG_HOME="$HOME/.config"
export DOTFILES="$HOME/dotfiles"
# For specific data
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
# # For cached files
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"
export ZDOTDIR="${DOTFILES}/zsh";
export ADOTDIR="${ZDOTDIR}/.antigen";

#=============================pathes

export CMAKE_INSTALL_PREFIX="/tmp/RPC"
export PATH="/usr/lib/ccache:$PATH"
export PATH="/usr/local/Qt-5.12.7/bin/:$PATH"
export PATH="${CMAKE_INSTALL_PREFIX}/bin/:${CMAKE_INSTALL_PREFIX}/examples:$PATH"
export PATH="${HOME}/go/bin/:$PATH"
export LD_LIBRARY_PATH="/usr/local/Qt-5.12.7/lib/:$LD_LIBRARY_PATH"
export PATH="$HOME/Qt/6.7.2/bin:$PATH"
export CMAKE_PREFIX_PATH="$HOME/Qt/6.7.2"
export RPC_BUILD_DIR="/opt/RPC-build"
export RPC_SOURCE_DIR="${HOME}/Documents/RPC/src"
export RPC_CLANG_TIDY="clang-tidy-14"
export CXXFLAGS="-fdiagnostics-color=always" 
export GIT_EDITOR=vim
#change it to "all" to see everything.
export BOOST_TEST_LOG_LEVEL=error
export PATH="$DOTFILES/scripts:$PATH"

#============================COMPILER
export CCACHE_MAXSIZE=40G

#export CC=clang-14
#export CXX=clang++-14
export CC=gcc-12
export CXX=g++-12

#export CC="gcc-7"
#export CXX="g++-7"
#export CC="clang-7"
#export CXX="clang++-7"

export CCACHE_DIR=/home/milad/.ccache
export CCACHE_TEMPDIR=/home/milad/.ccache

export DISTCC_HOSTS='--randomize 192.168.134.51/8,lzo 192.168.134.56/8,lzo localhost/6,lzo'
export DISTCC_VERBOSE=1
export DISTCC_LOG='/tmp/distcc.log'

