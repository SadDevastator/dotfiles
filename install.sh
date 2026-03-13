#!/usr/bin/env bash
set -euo pipefail

# Colors
RESET=$'\033[0m'
BOLD=$'\033[1m'
GREEN=$'\033[1;32m'
BLUE=$'\033[1;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'

info() { echo "${BLUE}${BOLD}==>${RESET} $1"; }
success() { echo "${GREEN}${BOLD} ✔${RESET} $1"; }
warn() { echo "${YELLOW}${BOLD} !${RESET} $1"; }
error() { echo "${RED}${BOLD} ✘${RESET} $1"; }

REPO_URL="https://github.com/SadDevastator/profile"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# --- Clone or locate repo ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$SCRIPT_DIR/config" ]; then
	if [ -d "$DOTFILES_DIR/.git" ]; then
		info "Updating existing dotfiles at $DOTFILES_DIR..."
		git -C "$DOTFILES_DIR" pull --ff-only
		success "Dotfiles updated"
	else
		info "Cloning dotfiles from $REPO_URL..."
		git clone "$REPO_URL" "$DOTFILES_DIR"
		success "Repository cloned to $DOTFILES_DIR"
	fi
	cd "$DOTFILES_DIR"
else
	cd "$SCRIPT_DIR"
	info "Running from local repo at $SCRIPT_DIR"
fi

# --- Copy configuration files ---
info "Copying configuration files..."
cp -r config/. ~/.config/
cp -r profile/. ~/
success "Configuration files copied"

# --- Precompile Zsh scripts ---
info "Precompiling Zsh scripts..."
~/.zsh/bin/precompile_zsh.sh
success "Zsh scripts precompiled"

# --- Oh My Zsh ---
ZSH_DIR="$HOME/.zsh/oh-my-zsh"
ZSH_CUSTOM_DIR="$ZSH_DIR/custom"

info "Setting up Oh My Zsh..."
if [ ! -d "$ZSH_DIR" ]; then
	git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
	success "Oh My Zsh installed"
else
	warn "Oh My Zsh already installed, skipping"
fi

# --- Zsh plugins ---
info "Installing Zsh plugins..."

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
	success "zsh-autosuggestions installed"
else
	warn "zsh-autosuggestions already installed, skipping"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
	success "zsh-syntax-highlighting installed"
else
	warn "zsh-syntax-highlighting already installed, skipping"
fi

# --- Powerlevel10k ---
info "Installing Powerlevel10k..."
if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
	success "Powerlevel10k installed"
else
	warn "Powerlevel10k already installed, skipping"
fi

if [ -f "$HOME/.p10k.zsh" ]; then
	success "Powerlevel10k config found at ~/.p10k.zsh"
else
	warn "No ~/.p10k.zsh found — run 'p10k configure' after first login"
fi

# --- Default shell ---
info "Setting default shell to Zsh..."
chsh -s "$(which zsh)"
success "Default shell set to Zsh"

cd ~

# --- Rust ---
info "Checking Rust installation..."
if ! command -v rustc &>/dev/null; then
	info "Rust not found, installing via rustup..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	source "$HOME/.cargo/env"
	success "Rust installed"
else
	warn "Rust already installed, skipping"
fi

# --- pokeget ---
info "Installing pokeget..."
cargo install pokeget

# --- WezTerm ---
WEZ_DIR="$HOME/wezterm"
BIN_DIR="$HOME/.local/bin"
REPO="https://github.com/wezterm/wezterm.git"
JOBS=8

export CARGO_BUILD_JOBS=$JOBS
export RUSTFLAGS="-C target-cpu=native"

info "Installing/Updating WezTerm..."

if ! command -v rustup >/dev/null 2>&1; then
	error "Rustup not found. Install rustup first."
	exit 1
fi

info "Updating Rust toolchain..."
rustup update
rustup default stable
success "Rust toolchain updated"

if [ ! -d "$WEZ_DIR/.git" ]; then
	info "Cloning WezTerm repository..."
	git clone --branch=main --recursive "$REPO" "$WEZ_DIR"
	success "WezTerm repository cloned"
else
	info "Updating WezTerm repository..."
	cd "$WEZ_DIR"
	git fetch origin main
	git reset --hard origin/main
	git submodule update --init --recursive
	success "WezTerm repository updated"
fi

cd "$WEZ_DIR"

info "Installing WezTerm dependencies..."
./get-deps
success "Dependencies installed"

mkdir -p .cargo
cat >.cargo/config.toml <<EOF
[build]
jobs = $JOBS

[profile.release]
incremental = false
codegen-units = 1
lto = "thin"
EOF

info "Building WezTerm (release mode, $JOBS threads)..."
cargo build --release
success "WezTerm built"

info "Linking binary to $BIN_DIR..."
mkdir -p "$BIN_DIR"
ln -sf "$WEZ_DIR/target/release/wezterm" "$BIN_DIR/wezterm"
success "WezTerm linked"

echo
success "All done! Restart your shell or run: exec zsh"
