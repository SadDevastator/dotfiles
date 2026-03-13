# User Profile Backup

Backup of my personal Linux user profile and application configuration files.

## Structure

```text
.
├── install.sh          # Setup script
├── config/             # XDG config files (~/.config/)
│   ├── fastfetch/      # Fastfetch system info display
│   └── tealdeer/       # Tealdeer (tldr) styling
└── profile/            # Home directory dotfiles (~/  )
    ├── .wezterm.lua    # WezTerm terminal config
    ├── .zshenv         # Zsh environment variables (all shells)
    ├── .zshrc          # Zsh interactive shell config
    ├── .zlogin         # Zsh login shell config
    └── .zsh/           # Modular Zsh scripts
        ├── aliases.zsh
        ├── plugins.zsh
        ├── env.zsh
        ├── lazy.zsh        # Lazy-loaded completions
        ├── conda.zsh
        ├── gh.zsh
        ├── zoxide.zsh
        └── bin/            # Zsh utility scripts
```

## Install

**One-liner (run directly from GitHub):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/SadDevastator/profile/main/install.sh)
```

**Or clone and run locally:**

```bash
git clone https://github.com/SadDevastator/profile ~/.profile
bash ~/.profile/install.sh
```

The script will:

1. Copy `config/` to `~/.config/` and `profile/` to `~/`
2. Precompile Zsh scripts
3. Clone [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) into `~/.zsh/ohmyzsh/`
4. Change the default shell to Zsh
5. Install [Rust](https://rustup.rs/) if not present
6. Clone and build [WezTerm](https://github.com/wezterm/wezterm) from source

## Tools & Dependencies

| Tool | Purpose |
| ---- | ------- |
| [Zsh](https://zsh.sourceforge.io/) | Shell |
| [Oh My Zsh](https://ohmyz.sh/) | Zsh framework & plugins |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | Zsh prompt theme |
| [WezTerm](https://wezfurlong.org/wezterm/) | Terminal emulator (built from source) |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display |
| [Tealdeer](https://github.com/tealdeer-rs/tealdeer) | `tldr` client |
| [lsd](https://github.com/lsd-rs/lsd) | Modern `ls` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [direnv](https://direnv.net/) | Per-directory environment variables |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for Git |
| [pokeget](https://github.com/talwat/pokeget-rs) | Pokémon sprites for Fastfetch |
| [Homebrew](https://brew.sh/) | Package manager (Linuxbrew) |
