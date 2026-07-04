# Auto-loaded by oh-my-zsh from $ZSH_CUSTOM. SLURM / enroot helpers.
# (Previously appended to ~/.zshrc by install.sh; now version-controlled.)

function node_attach() {
    # Attach to first allocated node
    ssh $(squeue --me --json | jq -r .jobs[0].nodes)
}

function container_attach() {
    # Attach to last container running on this machine
    enroot exec -- $(enroot list -f | tail -n 1 | awk '{print $2}') /bin/bash
}

function remote_container_attach() {
    # Attach to last container running on first allocated node
    ssh -t $(squeue --me --json | jq -r .jobs[0].nodes) 'enroot exec -- $(enroot list -f | tail -n 1 | awk '\''{print $2}'\'') /bin/bash'
}
