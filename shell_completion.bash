_notes()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "preview `ls ~/notes/`" -- $cur) )
}
complete -F _notes notes
