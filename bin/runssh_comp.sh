function _runssh () {
    local cur options COM_POSITION
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    echo ${COMP_WORDS[1]} >result
    # where is the COMMAND part of the argument (are we using -f?)
    COM_POSITION=1
    if [ ${COMP_WORDS[1]} ]; then
        if [ ${COMP_WORDS[1]} = '-f' ]; then
            COM_POSITION=3
        fi
    fi
    # complete path or commands according to the position.
    if [ ${COMP_CWORD} -gt $COM_POSITION ]; then
        options=$(${COMP_WORDS[@]:0:COMP_CWORD} ? 2>/dev/null)
    elif [ $COMP_CWORD -eq $COM_POSITION ]; then
        options="shell add del print import export"
    fi
    echo "$COM_POSITION, $COMP_CWORD, $options" >result
    COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
    return 0
}

complete -F _runssh bin/runssh
complete -F _runssh runssh
