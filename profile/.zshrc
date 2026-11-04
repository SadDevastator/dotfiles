eval "$(direnv hook zsh)"
export GH_CONFIG_DIR="$HOME/.config/gh-saddev"
[[ -t 1 ]] || return

# Run fastfetch first (fast, visual feedback)
fastfetch

# Enable Powerlevel10k instant prompt (must be before other output)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source "${HOME}/.zsh/plugins.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
