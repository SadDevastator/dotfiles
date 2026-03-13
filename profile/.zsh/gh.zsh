function gh() {
    if [[ "$PWD" == /mnt/Data/Repos/SEITech/* ]]; then
        GH_CONFIG_DIR=~/.config/gh-work command gh "$@"
    else
        GH_CONFIG_DIR=~/.config/gh-saddev command gh "$@"
    fi
}