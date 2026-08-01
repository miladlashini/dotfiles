#!/bin/bash
#
# install.sh - Provision a fresh Ubuntu/Debian machine with this dotfiles setup.
#
# This script installs system packages, multiple GCC/Clang toolchains, dev
# tools (VS Code, CMake built from source, Docker, Rust, Node via nvm, ...)
# and symlinks the configs in this repo (zsh, tmux, nvim) into place.
#
# It is the successor to install.legacy.sh (kept for reference/diffing) and
# is organized as one function per concern, run in order by main() at the
# bottom of the file.
#
# Requirements:
#   - Run as a user with sudo privileges (you'll be prompted once up front).
#   - DOTFILES, XDG_CONFIG_HOME and XDG_DATA_HOME must already be exported
#     (this repo's zsh/.zshenv sets them). If you haven't linked .zshenv yet,
#     export them manually before running, e.g.:
#       export DOTFILES="$HOME/dotfiles" XDG_CONFIG_HOME="$HOME/.config" \
#              XDG_DATA_HOME="$HOME/.config/local/share"
#
# Usage:
#   ./install.sh          # standard setup
#   ./install.sh qt       # standard setup + build QtBase from source
#   ./install.sh --help   # show this message
#
# The script is written to be safe to re-run: package installs are handled
# by apt/idempotent checks, and symlinking/cloning steps skip work that's
# already done (see link_if_missing()).

set -euo pipefail

# =============================================================================
# Helpers
# =============================================================================

log() { echo -e "\n==> $*"; }

usage() {
  # Print the usage message embedded in this script (lines 2-25).  
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

# Fail fast with a clear message instead of a cryptic "unbound variable" error
# if the dotfiles env vars this script depends on were never exported.
require_env_vars() {
  local missing=()
  for var in DOTFILES XDG_CONFIG_HOME XDG_DATA_HOME; do
    # Check if the variable is set and non-empty. If not, add it to the missing list.
    [ -n "${!var:-}" ] || missing+=("$var")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: required environment variable(s) not set: ${missing[*]}" >&2
    echo "Source zsh/.zshenv (or export them manually) before running this script." >&2
    exit 1
  fi
}

# Ask for sudo once, then keep the sudo timestamp alive for the lifetime of
# this script so a long build step (e.g. compiling CMake) doesn't hit a
# sudo password prompt in the background and stall.
start_sudo_keepalive() {
  if ! sudo -v; then
    echo "This script requires sudo privileges. Exiting." >&2
    exit 1
  fi
  # Keep sudo alive until the script exits.
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  # Ensure the background keepalive process is killed when the script exits.
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# Create a symlink at $dst pointing to $src.
# - No-op if the correct symlink already exists.
# - Backs up a pre-existing real file/dir to "$dst.backup" rather than
#   clobbering it.
link_if_missing() {
  local src="$1" dst="$2"

  if [ -L "$dst" ]; then
    echo "Symlink already exists: $dst"
    return
  fi

  if [ -e "$dst" ]; then
    echo "Backing up existing $dst to $dst.backup"
    mv "$dst" "$dst.backup"
  fi

  ln -s "$src" "$dst"
  echo "Linked $src -> $dst"
}

# =============================================================================
# Base system packages
# =============================================================================

install_base_packages() {
  log "Updating package index and installing base packages..."
  sudo apt update

  # Comprehensive set of development tools, utilities, and libraries for
  # C/C++, Python, Node.js, and general system management: compilers,
  # editors, version control, networking utilities, etc.
  # (neovim is intentionally excluded here - setup_neovim() installs a
  # current release directly, so pulling the apt version first would just
  # mean installing and immediately removing it.)
  sudo apt install -y build-essential git tig zsh tmux curl wget ncdu nload fzf silversearcher-ag \
    ninja-build gpg net-tools neofetch htop valgrind lcov doxygen ccache \
    libssl-dev python3 python3-pip python3-venv python3-dev npm \
    software-properties-common pkg-config libtool autoconf automake libgtest-dev libnm-dev openssh-server libboost-all-dev \
    libgoogle-glog-dev libudev-dev libsndfile1-dev libpulse-dev libsystemd-dev \
    btop iftop nethogs vnstat variety snapd obs-studio cowsay unrar djvulibre-bin libzip-dev ranger ueberzug \
    xdotool iperf netcat-traditional mpv ubuntu-restricted-extras gnome-tweaks ristretto shellcheck xxhash asciidoctor ruby-full

  sudo gem install asciidoctor-pdf
}

configure_git() {
  log "Configuring global git identity..."
  git config --global user.name "Milad Lashini"
  git config --global user.email "milad.lashini@gmail.com"
  git config --global core.editor vim
}

setup_ccache() {
  log "Setting up ccache..."
  mkdir -p "$HOME/.ccache"
  ccache -M 50G
}

# =============================================================================
# Compilers
# =============================================================================

install_multiple_gcc_versions() {
  log "Installing GCC/G++ (versions 10-14)..."
  sudo apt install -y gcc-10 g++-10 gcc-11 g++-11 gcc-12 g++-12 gcc-13 g++-13 gcc-14 g++-14
}

install_clang_versions() {
  log "Importing LLVM GPG key..."
  # NOTE: this only imports the key and removes stale llvm-*.list files; it
  # does not add an apt.llvm.org source list. Clang 14-19 below are expected
  # to come from Ubuntu's own repos. If a target release doesn't ship one of
  # these versions, add the matching apt.llvm.org deb line before this step.
  sudo rm -f /usr/share/keyrings/llvm-archive-keyring.gpg
  sudo rm -f /etc/apt/sources.list.d/llvm-*.list
  curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | \
    sudo tee /usr/share/keyrings/llvm-archive-keyring.gpg > /dev/null

  log "Installing Clang 14-19 and related tools..."
  for version in 14 15 16 17 18 19; do
    sudo apt install -y "clang-$version" "clang-tidy-$version" "clang-format-$version"
  done
}

# =============================================================================
# Editors / IDE tooling
# =============================================================================

install_vscode() {
  if command -v code &>/dev/null; then
    log "Visual Studio Code already installed, skipping."
  else
    log "Installing Visual Studio Code..."
    local keyring
    keyring="$(mktemp -d)/microsoft.gpg"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$keyring"
    sudo install -o root -g root -m 644 "$keyring" /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f "$keyring"
    sudo apt update
    sudo apt install -y code
  fi

  code --install-extension ms-vscode.cpptools
  code --install-extension ms-python.python
}

build_and_install_cmake() {
  local cmake_version="3.29.3"
  local cmake_tar="cmake-$cmake_version.tar.gz"
  local cmake_dir="cmake-$cmake_version"

  if command -v cmake &>/dev/null && [[ "$(cmake --version | head -1)" == *"$cmake_version"* ]]; then
    log "CMake $cmake_version already installed, skipping."
    return
  fi

  log "Building CMake $cmake_version from source..."
  local build_root
  build_root="$(mktemp -d)"
  (
    cd "$build_root"
    wget "https://github.com/Kitware/CMake/releases/download/v$cmake_version/$cmake_tar"
    tar -xzf "$cmake_tar"
    cd "$cmake_dir"
    CC=/usr/bin/gcc CXX=/usr/bin/g++ ./bootstrap
    make -j"$(nproc)"
    sudo make install
  )
  rm -rf "$build_root"
}

# =============================================================================
# Python
# =============================================================================

setup_python_venv() {
  log "Setting up Python dev virtualenv at ~/dev/env/venv..."
  mkdir -p ~/dev/env
  if [ ! -d ~/dev/env/venv ]; then
    python3 -m venv ~/dev/env/venv
    echo "Created virtual environment at ~/dev/env/venv"
  fi

  # shellcheck disable=SC1090
  source ~/dev/env/venv/bin/activate
  pip install --upgrade pip
  pip install pytest ipython flake8 black mypy
  deactivate
}

# =============================================================================
# QtBase (optional - only runs when "qt" is passed as the first argument)
# =============================================================================

build_qtbase() {
  log "Building QtBase from source..."

  local qt_version="6.7.2"
  local qt_repo="https://code.qt.io/qt/qtbase.git"
  local qt_src_dir="$HOME/dev/qtbase"
  local qt_build_dir="$HOME/dev/qtbase-build"
  local qt_install_dir="$HOME/Qt/$qt_version-core"

  sudo apt install -y build-essential cmake ninja-build perl python3 \
    libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxcb-keysyms1-dev \
    libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev \
    libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev \
    libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev \
    libxcb-cursor-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev \
    libjpeg-dev libssl-dev ntp cups ffmpeg libprotobuf-dev protobuf-compiler

  if [ ! -d "$qt_src_dir" ]; then
    git clone --branch "v$qt_version" --depth 1 "$qt_repo" "$qt_src_dir"
  fi

  mkdir -p "$qt_build_dir"
  (
    cd "$qt_build_dir"
    cmake "$qt_src_dir" \
      -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$qt_install_dir" \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_BUILD_TESTS=OFF
    ninja -j"$(nproc)"
    ninja install
  )

  echo "==> QtBase installed in $qt_install_dir"
}

# =============================================================================
# Docker
# =============================================================================

install_docker() {
  log "Installing Docker (idempotent)..."

  if snap list 2>/dev/null | grep -q '^docker'; then
    log "Removing Snap Docker..."
    sudo snap remove docker --purge || true
    sudo rm -rf /var/snap/docker ~/snap/docker
  fi

  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release

  local docker_keyring="/etc/apt/keyrings/docker.asc"
  if [ ! -f "$docker_keyring" ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$docker_keyring"
    sudo chmod a+r "$docker_keyring"
  fi

  local docker_list="/etc/apt/sources.list.d/docker.list"
  if [ ! -f "$docker_list" ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=$docker_keyring] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee "$docker_list" > /dev/null
  fi

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo systemctl enable docker.socket || true
  sudo systemctl enable docker || true
  sudo systemctl start docker.socket || true
  sudo systemctl start docker || true

  if ! groups "$USER" | grep -q "\bdocker\b"; then
    sudo usermod -aG docker "$USER"
    echo "==> User $USER added to docker group. Log out and back in for group changes to take effect."
  fi

  log "Waiting for Docker daemon to be ready..."
  for _ in {1..10}; do
    if docker info >/dev/null 2>&1; then
      echo "==> Docker is running!"
      break
    fi
    sleep 2
  done
}

# =============================================================================
# Yocto build dependencies
# =============================================================================

install_yocto_dependencies() {
  log "Installing Yocto build dependencies..."
  sudo apt install -y gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 python3-subunit zstd liblz4-tool \
    file locales libacl1 bmap-tools
}

# =============================================================================
# Google Chrome
# =============================================================================

install_google_chrome() {
  log "Installing Google Chrome (stable)..."

  local deb_path
  deb_path="$(mktemp -d)/google-chrome.deb"
  wget -qO "$deb_path" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y "$deb_path"
  rm -f "$deb_path"
  echo "Google Chrome installed successfully."

  # Also register Google's apt repo so future updates come through `apt
  # upgrade` instead of requiring another manual .deb download.
  log "Adding Google Chrome apt repository..."
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main' | \
    sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
}

# =============================================================================
# zsh dotfiles
# =============================================================================

link_zsh_dotfiles() {
  log "Linking zsh dotfiles..."
  link_if_missing "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
  link_if_missing "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
}

# =============================================================================
# Rust & Tree-sitter
# =============================================================================

install_rust_and_tree_sitter() {
  log "Setting up Rust toolchain..."
  if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  else
    echo "rustup already installed"
  fi
  export PATH="$HOME/.cargo/bin:$PATH"

  rustup default stable
  rustc --version
  cargo --version

  log "Installing Tree-sitter CLI..."
  if ! command -v tree-sitter >/dev/null 2>&1; then
    cargo install --locked tree-sitter-cli
  else
    echo "Tree-sitter CLI already installed: $(tree-sitter --version)"
  fi

  tree-sitter --version || {
    echo "ERROR: Tree-sitter CLI failed to install" >&2
    exit 1
  }
}

# =============================================================================
# tmux
# =============================================================================

setup_tmux() {
  log "Setting up tmux..."
  mkdir -p "$XDG_CONFIG_HOME/tmux"
  mkdir -p "$XDG_CONFIG_HOME/tmux/scripts"
  link_if_missing "$DOTFILES/tmux/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
  link_if_missing "$DOTFILES/tmux/scripts/popup.zsh" "$XDG_CONFIG_HOME/tmux/scripts/popup.zsh"

  if [ ! -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$XDG_CONFIG_HOME/tmux/plugins/tpm"
  fi
}

# =============================================================================
# Neovim
# =============================================================================

setup_neovim() {
  log "Setting up Neovim..."

  sudo apt install -y ripgrep fd-find clangd git curl

  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
  fi

  log "Installing latest Neovim release..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fL -o "$tmp_dir/nvim-linux-x86_64.tar.gz" \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf "$tmp_dir/nvim-linux-x86_64.tar.gz"
  rm -rf "$tmp_dir"
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

  mkdir -p "$XDG_CONFIG_HOME/nvim"
  mkdir -p "$XDG_DATA_HOME/nvim"
  link_if_missing "$DOTFILES/nvim" "$XDG_CONFIG_HOME/nvim"

  log "Installing lazy.nvim (plugin manager)..."
  local lazy_dir="$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
  if [ ! -d "$lazy_dir" ]; then
    git clone https://github.com/folke/lazy.nvim.git "$lazy_dir"
  fi

  log "Installing JetBrainsMono Nerd Font..."
  mkdir -p "$HOME/.local/share/fonts"
  (
    cd "$HOME/.local/share/fonts"
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip
    rm -f JetBrainsMono.zip
  )
  fc-cache -fv

  echo "Neovim setup complete. Start it with: nvim (plugins auto-install on first launch)"
}

install_bash_language_server() {
  log "Installing bash-language-server..."
  sudo snap install bash-language-server --classic
}

integrate_tmux_neovim() {
  log "Setting up tmux <-> Neovim integration..."

  local tmux_conf="$XDG_CONFIG_HOME/tmux/tmux.conf"
  if ! grep -q "christoomey/vim-tmux-navigator" "$tmux_conf"; then
    echo "Adding vim-tmux-navigator to tmux plugins..."
    printf "\nset -g @plugin 'christoomey/vim-tmux-navigator'\n" >> "$tmux_conf"
  fi

  if [ -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ]; then
    "$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
  fi

  echo "tmux <-> Neovim integration complete."
}

# =============================================================================
# Node.js / nvm
# =============================================================================

install_node_via_nvm() {
  log "Installing nvm and Node 22..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  export NVM_DIR="$HOME/.config/nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
  else
    echo "ERROR: nvm.sh not found in $NVM_DIR" >&2
    exit 1
  fi

  command -v nvm >/dev/null 2>&1 || {
    echo "ERROR: nvm failed to load" >&2
    exit 1
  }

  nvm install 22
  nvm alias default 22
}

# =============================================================================
# Manual / optional steps not automated by this script
# =============================================================================
#
# keyd - remap function keys to volume controls (used for tmux popups):
#   git clone https://github.com/rvaiya/keyd.git /tmp/keyd && cd /tmp/keyd
#   make && sudo make install
#   sudo systemctl enable keyd
#
#   Then, matching your keyboard's vendor:product ID from `lsusb` (device may
#   show up as the USB receiver rather than the keyboard itself):
#     sudo tee /etc/keyd/<device>.conf > /dev/null << 'EOF'
#     [ids]
#     046d:c548
#
#     [main]
#     volumeup = f12
#     volumedown = f11
#     mute = f10
#     EOF
#   sudo systemctl restart keyd
#
# NVIDIA prime rendering issues:
#   prime-select query
#   sudo prime-select nvidia

# =============================================================================
# main
# =============================================================================

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_env_vars
  start_sudo_keepalive

  install_base_packages
  configure_git
  setup_ccache

  install_multiple_gcc_versions
  install_clang_versions

  install_vscode
  build_and_install_cmake

  setup_python_venv

  if [[ "${1:-}" == "qt" ]]; then
    build_qtbase
  fi

  install_docker
  install_yocto_dependencies
  install_google_chrome

  link_zsh_dotfiles
  install_rust_and_tree_sitter

  setup_tmux
  setup_neovim
  install_bash_language_server
  integrate_tmux_neovim

  install_node_via_nvm

  log "Done! Start Neovim with: nvim"
}

main "$@"
