# Run precompile only once per login session
_precompile_marker="${XDG_RUNTIME_DIR:-/tmp}/precompile_zsh.done"
if [[ ! -f "$_precompile_marker" ]]; then
    $HOME/.zsh/bin/precompile_zsh.sh &!
    touch "$_precompile_marker"
fi
unset _precompile_marker