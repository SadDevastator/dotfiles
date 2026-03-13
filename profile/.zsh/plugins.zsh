# Completion, and plugin sourcing

# oh-my-zsh plugins - only lightweight ones loaded immediately
# Heavy tools (kubectl, helm, terraform, etc.) are lazy-loaded below
plugins=(
    archlinux
    command-not-found
    cp
    dotenv
    extract
    fzf
    gpg-agent
    git
    history
    sudo
    systemd
    zsh-autosuggestions
    zsh-syntax-highlighting
)
# Load environment variables from env.zsh first
source "${HOME}/.zsh/env.zsh"
# oh-my-zsh setup
source "${HOME}/.zsh/oh-my-zsh/oh-my-zsh.sh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# compinit with cache - only regenerate once per day
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Only regenerate completion dump once per day
if [[ -n "$ZSH_COMPDUMP"(#qN.mh+24) ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi

# Source all other .zsh files in ~/.zsh/ except this one and env.zsh
# Source aliases first (fast), then lazy loaders, then others
this_file="${0:A}"
env_file="${HOME}/.zsh/env.zsh"

# Load aliases immediately (they're cheap)
[[ -f "${HOME}/.zsh/aliases.zsh" ]] && source "${HOME}/.zsh/aliases.zsh"

# Load lazy loaders
[[ -f "${HOME}/.zsh/lazy.zsh" ]] && source "${HOME}/.zsh/lazy.zsh"

# Load remaining files
for f in "$HOME/.zsh/"*.zsh; do
    [[ "$f" == "$this_file" ]] && continue
    [[ "$f" == "$env_file" ]] && continue
    [[ "$f" == "${HOME}/.zsh/aliases.zsh" ]] && continue
    [[ "$f" == "${HOME}/.zsh/lazy.zsh" ]] && continue
    source "$f"
done
