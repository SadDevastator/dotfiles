# =============================================================================
# Lazy-loading for heavy CLI tools
# These tools have slow init times, so we defer loading until first use
# =============================================================================

# --- Helper function for lazy-loading completions ---
__lazy_load_completion() {
    local cmd=$1
    local plugin_path=$2
    if [[ -f "$plugin_path" ]]; then
        source "$plugin_path"
    fi
}

# --- kubectl / kubernetes ---
if command -v kubectl &>/dev/null; then
    kubectl() {
        unfunction kubectl
        source "$ZSH/plugins/kubectl/kubectl.plugin.zsh" 2>/dev/null
        kubectl "$@"
    }
fi

# --- helm ---
if command -v helm &>/dev/null; then
    helm() {
        unfunction helm
        source "$ZSH/plugins/helm/helm.plugin.zsh" 2>/dev/null
        helm "$@"
    }
fi

# --- terraform ---
if command -v terraform &>/dev/null; then
    terraform() {
        unfunction terraform
        source "$ZSH/plugins/terraform/terraform.plugin.zsh" 2>/dev/null
        terraform "$@"
    }
    alias tf='terraform'
fi

# --- docker/podman (completions) ---
if command -v podman &>/dev/null; then
    _lazy_podman_init() {
        unfunction podman 2>/dev/null
        source "$ZSH/plugins/podman/podman.plugin.zsh" 2>/dev/null
    }
    podman() {
        _lazy_podman_init
        podman "$@"
    }
fi

# --- docker-compose / podman-compose ---
if command -v podman-compose &>/dev/null; then
    podman-compose() {
        unfunction podman-compose
        source "$ZSH/plugins/docker-compose/docker-compose.plugin.zsh" 2>/dev/null
        podman-compose "$@"
    }
fi

# --- gh (GitHub CLI) ---
if command -v gh &>/dev/null; then
    gh() {
        unfunction gh
        source "$ZSH/plugins/gh/gh.plugin.zsh" 2>/dev/null
        gh "$@"
    }
fi

# --- nvm (Node Version Manager) - very slow ---
export NVM_DIR="$HOME/.nvm"
export NVM_LAZY_LOAD=true
if [[ -d "$NVM_DIR" ]]; then
    nvm() {
        unfunction nvm node npm npx 2>/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        nvm "$@"
    }
    node() {
        unfunction nvm node npm npx 2>/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        node "$@"
    }
    npm() {
        unfunction nvm node npm npx 2>/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        npm "$@"
    }
    npx() {
        unfunction nvm node npm npx 2>/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        npx "$@"
    }
fi

# --- rbenv ---
if command -v rbenv &>/dev/null; then
    rbenv() {
        unfunction rbenv
        eval "$(command rbenv init -)"
        source "$ZSH/plugins/rbenv/rbenv.plugin.zsh" 2>/dev/null
        rbenv "$@"
    }
    # Also lazy-load ruby commands
    ruby() {
        unfunction ruby rbenv 2>/dev/null
        eval "$(command rbenv init -)"
        ruby "$@"
    }
    gem() {
        unfunction gem rbenv 2>/dev/null
        eval "$(command rbenv init -)"
        gem "$@"
    }
    bundle() {
        unfunction bundle rbenv 2>/dev/null
        eval "$(command rbenv init -)"
        source "$ZSH/plugins/bundler/bundler.plugin.zsh" 2>/dev/null
        bundle "$@"
    }
    rake() {
        unfunction rake rbenv 2>/dev/null
        eval "$(command rbenv init -)"
        source "$ZSH/plugins/rake/rake.plugin.zsh" 2>/dev/null
        rake "$@"
    }
fi

# --- flutter ---
if command -v flutter &>/dev/null; then
    flutter() {
        unfunction flutter
        source "$ZSH/plugins/flutter/flutter.plugin.zsh" 2>/dev/null
        flutter "$@"
    }
fi

# --- gradle ---
if command -v gradle &>/dev/null; then
    gradle() {
        unfunction gradle
        source "$ZSH/plugins/gradle/gradle.plugin.zsh" 2>/dev/null
        gradle "$@"
    }
fi

# --- arduino-cli ---
if command -v arduino-cli &>/dev/null; then
    arduino-cli() {
        unfunction arduino-cli
        source "$ZSH/plugins/arduino-cli/arduino-cli.plugin.zsh" 2>/dev/null
        arduino-cli "$@"
    }
fi

# --- brew (if on Linux with Linuxbrew) ---
if command -v brew &>/dev/null; then
    brew() {
        unfunction brew
        source "$ZSH/plugins/brew/brew.plugin.zsh" 2>/dev/null
        brew "$@"
    }
fi

# --- rust/cargo ---
if command -v cargo &>/dev/null; then
    cargo() {
        unfunction cargo
        source "$ZSH/plugins/rust/rust.plugin.zsh" 2>/dev/null
        cargo "$@"
    }
    rustc() {
        unfunction rustc
        source "$ZSH/plugins/rust/rust.plugin.zsh" 2>/dev/null
        rustc "$@"
    }
    rustup() {
        unfunction rustup
        source "$ZSH/plugins/rust/rust.plugin.zsh" 2>/dev/null
        rustup "$@"
    }
fi

# --- pip / python extras ---
pip() {
    unfunction pip 2>/dev/null
    source "$ZSH/plugins/pip/pip.plugin.zsh" 2>/dev/null
    pip "$@"
}
pip3() {
    unfunction pip3 2>/dev/null
    source "$ZSH/plugins/pip/pip.plugin.zsh" 2>/dev/null
    pip3 "$@"
}

# --- tailscale ---
if command -v tailscale &>/dev/null; then
    tailscale() {
        unfunction tailscale
        source "$ZSH/plugins/tailscale/tailscale.plugin.zsh" 2>/dev/null
        tailscale "$@"
    }
fi

# --- kompose ---
if command -v kompose &>/dev/null; then
    kompose() {
        unfunction kompose
        source "$ZSH/plugins/kompose/kompose.plugin.zsh" 2>/dev/null
        kompose "$@"
    }
fi

# --- ufw ---
if command -v ufw &>/dev/null; then
    ufw() {
        unfunction ufw
        source "$ZSH/plugins/ufw/ufw.plugin.zsh" 2>/dev/null
        command ufw "$@"
    }
fi

# --- rsync ---
rsync() {
    unfunction rsync 2>/dev/null
    source "$ZSH/plugins/rsync/rsync.plugin.zsh" 2>/dev/null
    command rsync "$@"
}

# --- systemadmin ---
# Load systemadmin aliases on first use of any admin command
__load_systemadmin() {
    unfunction __load_systemadmin 2>/dev/null
    source "$ZSH/plugins/systemadmin/systemadmin.plugin.zsh" 2>/dev/null
}
