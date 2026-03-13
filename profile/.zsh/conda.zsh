# Lazy-load conda shell integration on first invocation.
# This avoids the slow default init at shell startup.
conda() {
    unset -f conda
    if [[ -f /opt/miniconda3/etc/profile.d/conda.sh ]]; then
        source /opt/miniconda3/etc/profile.d/conda.sh
        conda "$@"
    else
        command conda "$@"
    fi
}
