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
alias grbu='git rebase upstream/main'
alias gdu='git diff upstream/main'
alias ng='noglob'

# Define a function to automatically set the SSH_ALIAS and then connect so that you can prepend name_of_server to prompt
function ssh() {
  # $1 will be the first argument (your short host alias)
  if [[ -n "$1" ]]; then
    # Use LC_PROMPT_ALIAS to pass the alias name, as LC_* variables are often accepted
    # Abuse this env hoping it's already accepted by server
    export LC_PROMPT_ALIAS="$1"
    echo $LC_PROMPT_ALIAS
    
    # Use the ssh command, explicitly telling it to send the variable
    # Note: We must also pass the -o "SendEnv LC_PROMPT_ALIAS" option.
    /usr/bin/ssh -o "SendEnv LC_PROMPT_ALIAS" "$@"
    
    # Unset the variable on disconnect (optional cleanup)
    unset LC_PROMPT_ALIAS
  else
    # If no host is provided, fall back to the standard ssh
    /usr/bin/ssh "$@"
  fi
}
