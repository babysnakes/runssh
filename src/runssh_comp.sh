function _runssh () {
    local cur options
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    options=$(${COMP_WORDS[@]:0:COMP_CWORD} -l 2>/dev/null)
    COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
    return 0
}

complete -F _runssh bin/runssh
complete -F _runssh runssh