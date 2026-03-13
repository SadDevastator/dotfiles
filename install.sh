#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/SadDevastator/profile"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.profile}"

# When run via curl|bash, BASH_SOURCE[0] is /dev/stdin — no local repo.
# Clone the repo so all relative paths are available.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$SCRIPT_DIR/config" ]; then
    echo "Cloning dotfiles from $REPO_URL..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
else
    cd "$SCRIPT_DIR"
fi

# Copy configuration files
cp -r config/ ~/.config/
cp -r profile/ ~/

# Precompile Zsh scripts
~/.zsh/bin/precompile_zsh.sh

# Install Oh My Zsh
cd ~/.zsh
if [ ! -d ohmyzsh ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git
else
    echo "Oh My Zsh is already installed. Skipping installation."
fi

# Change default shell to Zsh
chsh -s $(which zsh)

# Return to home directory
cd ~

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "Rust is already installed. Skipping Rust installation."
fi

# Clone and build WezTerm
if [ ! -d wezterm ]; then
    git clone --depth=1 --branch=main --recursive https://github.com/wezterm/wezterm.git
    cd wezterm
    git submodule update --init --recursive
    ./get-deps
    cargo build --release
    cargo run --release --bin wezterm -- start
else
    echo "WezTerm is already cloned. Skipping cloning and building."
fi
