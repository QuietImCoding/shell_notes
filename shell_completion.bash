_notes()
{
    accepted_cmds="preview update search register"
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$accepted_cmds `ls ~/notes/`" -- $cur) )
}
complete -F _notes notes
