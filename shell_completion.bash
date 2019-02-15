_notes()
{
    accepted_cmds="preview "
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$accepted_mcds `ls ~/notes/`" -- $cur) )
}
complete -F _notes notes
