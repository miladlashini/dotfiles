#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Prompt for sudo access at the beginning
if ! sudo -v; then
  echo "This script requires sudo privileges. Exiting."
  exit 1
fi

###############
# Installation #
###############

# Update package index
sudo apt update

# Install packages
sudo apt install -y build-essential neovim git tig zsh tmux curl wget ncdu nload fzf silversearcher-ag \
ninja-build gpg net-tools neofetch htop valgrind lcov doxygen ccache \
libssl-dev python3 python3-pip python3-venv python3-dev \
software-properties-common pkg-config libtool autoconf automake libgtest-dev libnm-dev openssh-server libboost-all-dev \
libgoogle-glog-dev libudev-dev libsndfile1-dev libpulse-dev libsystemd-dev \
btop iftop nethogs vnstat nload variety snapd obs-studio doxygen cowsay unrar djvulibre-bin libzip-dev \
xdotool iperf netcat-traditional mpv ubuntu-restricted-extras gnome-tweaks ristretto shellcheck xxhash tree-sitter-cli

# Replace with your actual name and email
git config --global user.name "Milad Lashini"
git config --global user.email "milad.lashini@gmail.com"
git config --global core.editor vim


sudo mkdir -p /home/milad/.ccache
sudo chown -R "$USER":"$USER" /home/milad/.ccache

export CCACHE_DIR=/home/milad/.ccache
ccache -M 50G 

##########################################
# Install multiple GCC and Clang versions
##########################################

echo "Installing GCC, G++ (versions 10–13) and latest Clang tools..."

# Add Ubuntu Toolchain PPA (for gcc/g++ 12 and 13)
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt update

# Install multiple gcc/g++ versions
sudo apt install -y gcc-10 g++-10 gcc-11 g++-11 gcc-12 g++-12 gcc-13 g++-13 gcc-14 g++-14

###############################################
# Install Clang (versions 14 to 18) and tools #
###############################################

##########################################
# Import official LLVM GPG key (correctly)
##########################################

echo "Importing LLVM GPG key..."
# Clean up any old keyrings
sudo rm -f /usr/share/keyrings/llvm-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/llvm-*.list

# Add the official GPG key
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | \
  sudo tee /usr/share/keyrings/llvm-archive-keyring.gpg > /dev/null

echo "Installing Clang 14–19 and related tools..."

# Install Clang compilers and tools
for version in 14 15 16 17 18 19; do
sudo apt install -y clang-$version clang-tidy-$version clang-format-$version
done

# Install VS Code (official Microsoft repo)
if ! command -v code &> /dev/null; then
  echo "Installing Visual Studio Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
  sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  rm microsoft.gpg
  sudo apt update
  sudo apt install -y code
else
  echo "Visual Studio Code is already installed."
fi

code --install-extension ms-vscode.cpptools
code --install-extension ms-python.python

###############################
# Build & Install CMake (latest)
###############################

CMAKE_VERSION=3.29.3
CMAKE_TAR=cmake-$CMAKE_VERSION.tar.gz
CMAKE_DIR=cmake-$CMAKE_VERSION

if ! command -v cmake &>/dev/null || [[ "$(cmake --version | head -1)" != *"$CMAKE_VERSION"* ]]; then
  echo "Installing CMake $CMAKE_VERSION from source..."
  cd /tmp
  wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/$CMAKE_TAR
  tar -xzf $CMAKE_TAR
  cd $CMAKE_DIR
  # Explicitly set compilers
  export CC=/usr/bin/gcc
  export CXX=/usr/bin/g++
  ./bootstrap
  make -j"$(nproc)"
  sudo make install
  cd ~
  rm -rf /tmp/$CMAKE_DIR /tmp/$CMAKE_TAR
else
  echo "CMake $CMAKE_VERSION is already installed."
fi


##################
# Python Setup   #
##################

# Create a development venv in ~/dev/env if not present
mkdir -p ~/dev/env
if [ ! -d ~/dev/env/venv ]; then
  python3 -m venv ~/dev/env/venv
  echo "Created virtual environment at ~/dev/env/venv"
fi

# Activate and install common Python dev tools
source ~/dev/env/venv/bin/activate
pip install --upgrade pip
pip install pytest ipython flake8 black mypy

deactivate


##########################################
# Build QtBase only (if 'qt' arg passed) #
##########################################

if [[ "$1" == "qt" ]]; then
  echo "==> Building QtBase from source..."

  QT_VERSION=6.7.2
  QT_REPO="https://code.qt.io/qt/qtbase.git"
  QT_SRC_DIR="$HOME/dev/qtbase"
  QT_BUILD_DIR="$HOME/dev/qtbase-build"
  QT_INSTALL_DIR="$HOME/Qt/$QT_VERSION-core"

  # Install QtBase build dependencies
  sudo apt install -y build-essential cmake ninja-build perl python3 \
    libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxcb-keysyms1-dev \
    libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev \
    libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev \
    libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev \
    libxcb-cursor-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev \
    libjpeg-dev libssl-dev ntp cups ffmpeg libprotobuf-dev

  # Clone qtbase if not already present
  if [ ! -d "$QT_SRC_DIR" ]; then
    git clone --branch v$QT_VERSION --depth 1 "$QT_REPO" "$QT_SRC_DIR"
  fi

  # Configure and build
  mkdir -p "$QT_BUILD_DIR"
  cd "$QT_BUILD_DIR"

  cmake "$QT_SRC_DIR" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$QT_INSTALL_DIR" \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF

  ninja -j"$(nproc)"
  ninja install

  echo "==> QtBase installed in $QT_INSTALL_DIR"
fi

#########################
# Install Docker (docker.io)
#########################

echo "Installing Docker..."

sudo apt install -y docker.io

sudo systemctl enable --now docker

# Add current user to docker group
sudo usermod -aG docker "$USER"

echo "Docker installed and running. You may need to log out and log back in for group changes to take effect."

#For NVIDIA to solve the rendering problem
#prime-select query
#sudo prime-select nvidia


#########################
# Install Google Chrome (Stable)
#########################

echo "Installing Google Chrome (Stable)..."

wget -qO /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo apt install -y /tmp/google-chrome.deb

rm /tmp/google-chrome.deb

echo "Google Chrome installed successfully."

# Add Google Chrome repo and key
echo "Adding Google Chrome repository..."

wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' | \
  sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

########
# zsh #
########

# Creates the link if missing
# Replaces incorrect links
# Does not touch real files

link_if_missing() {
    src="$1"
    dst="$2"

    if [ -L "$dst" ]; then
        return
    elif [ -e "$dst" ]; then
        echo "Skipping $dst (exists and is not a symlink)"
    else
        ln -s "$src" "$dst"
    fi
}

link_if_missing "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
link_if_missing "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

########
# tmux #
########
mkdir -p "$XDG_CONFIG_HOME/tmux"
link_if_missing "$DOTFILES/tmux/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"

if [ ! -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm \
        "$XDG_CONFIG_HOME/tmux/plugins/tpm"
fi

###########
# neovim #
###########

echo "Setting up Neovim..."

# Packages (sudo already granted earlier in your script)
sudo apt install -y \
    ripgrep \
    fd-find \
    clangd \
    git \
    curl

sudo apt remove -y neovim

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim


# fd compatibility (Ubuntu naming)
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# XDG paths
mkdir -p "$XDG_CONFIG_HOME/nvim"
mkdir -p "$XDG_DATA_HOME/nvim"

# Symlink Neovim config
link_if_missing "$DOTFILES/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"

echo "Installing lazy.nvim..."

# lazy.nvim (plugin manager)
LAZY_DIR="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_DIR" ]; then
    git clone https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
fi

# JetBrainsMono Nerd Font.
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
fc-cache -fv


echo "Neovim setup complete."
echo "Done!"
echo "Start Neovim with: nvim"
echo "Plugins will auto-install on first launch."

#############################
# tmux <-> neovim integration
#############################

echo "Setting up tmux <-> Neovim integration..."

# Ensure TPM plugin line exists
TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"

if ! grep -q "christoomey/vim-tmux-navigator" "$TMUX_CONF"; then
    echo "Adding vim-tmux-navigator to tmux plugins..."
    printf "\nset -g @plugin 'christoomey/vim-tmux-navigator'\n" >> "$TMUX_CONF"
fi

# Install TPM plugins automatically (non-interactive)
if [ -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ]; then
    "$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
fi

echo "tmux <-> Neovim integration complete."

