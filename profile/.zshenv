export TERM=xterm-256color
export ZSH_CUSTOM="${HOME}/.zsh/oh-my-zsh/custom"
export ZSH="$HOME/.zsh/oh-my-zsh"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH="/opt/anaconda/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/texlive/2025/bin/x86_64-linux:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/pnpm/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
typeset -gU path PATH
# WezTerm/noctalia run with NVIDIA-only EGL to skip loading Mesa; don't pass it on:
# inside Flatpaks that path doesn't exist and GL would break
unset __EGL_VENDOR_LIBRARY_FILENAMES
