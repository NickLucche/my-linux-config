alias p='python3'
alias gs='git status'
alias build='BUILDX_EXPERIMENTAL=1 docker buildx debug --invoke /bin/sh --on=error build .'
alias rgf='rg --files | rg'
pv() {
    python -c "import $1; print(getattr($1, '__version__', 'Version not found'))"
}
alias gfu='git fetch upstream'
alias gcou='git checkout upstream/main'
alias k='kubectl'
alias pip="noglob pip"
alias pytest="noglob pytest"

