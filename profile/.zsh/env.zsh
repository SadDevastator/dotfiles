export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[bf]g:c:clear:history:exit:q:pwd:* --help"
export LESS_TERMCAP_md="$(tput bold 2> /dev/null; tput setaf 2 2> /dev/null)"
export LESS_TERMCAP_me="$(tput sgr0 2> /dev/null)"
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
export OPENSSL_MODULES=/opt/anaconda/lib/ossl-modules
export CHROME_EXECUTABLE="google-chrome-stable"
export ANI_CLI_PLAYER=vlc
export EDITOR='nano'
DISABLE_UPDATE_PROMPT=false
export DISABLE_UPDATE_PROMPT
ZSH_DISABLE_COMPFIX=false
export ZSH_DISABLE_COMPFIX
DISABLE_AUTO_UPDATE=false
export DISABLE_AUTO_UPDATE
CASE_SENSITIVE=false
export CASE_SENSITIVE
TERM_PROGRAM=""
export TERM_PROGRAM
DISABLE_LS_COLORS=false
export DISABLE_LS_COLORS
BUNDLED_COMMANDS=""
export BUNDLED_COMMANDS
HYPHEN_INSENSITIVE=false
export HYPHEN_INSENSITIVE
INSIDE_EMACS=false
export INSIDE_EMACS
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
ZSH_THEME="powerlevel10k/powerlevel10k"