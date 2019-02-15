_show_todays_notes() {
    for dir in $@
    do
	dname="`date | awk '{ printf \"%s_%d_%d\", $2, $3, $6 }'`"
	for fname in `ls $dir`
	do
	    echo ${fname:$((${#dname}+1)):${#fname}}
	done
    done
}

_get_subjects() {
    for f in $@
    do
	echo $f | sed -E 's/.*[a-zA-Z]{3}_[0-9]{1,2}_[0-9]{4}_//g' | cut -d'.' -f1
    done
}


_generate_toc() {
    echo "# Table of Contents #"
    for f in $@
    do
	echo "## Notes for $(_get_subjects $f) ##"
	cur_inc=0
	headers="$(cat $f | awk '$1 ~ "#+" { $1="";$NF=""; printf( "%s;", $0 )}')"
	for i in $(seq 1 `awk -F";" '{print NF-1}' <<< "$headers"`)
	do
	    h="`echo $headers | cut -d';' -f"$i" | xargs`"
	    id="$(echo $h | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
	    echo "$((cur_inc + i)). [$h](#$id)"
	done
	cur_inc=$((cur_inc + i))
	echo
    done
    echo '$\pagebreak$'
}



_todays_notes() {
    rm ~/notes/today/* 2>/dev/null
    rm `find ~/notes/ | grep '~'` 2>/dev/null
    dname="`date | awk '{ printf \"%s_%d_%d\", $2, $3, $6 }'`"
    for fname in `find ~/notes | grep md$`
    do
	if [[ $fname = *$dname* ]]; then
	    cp $fname ~/notes/today/
	fi
    done
}

_preview_notes() {
    today=~/notes/today/
    if [[ $# -eq 0 ]]; then
	dname="`date | awk '{ printf \"%s_%d_%d\", $2, $3, $6 }'`"
	echo "`_generate_toc $today$(ls $today)`" > /tmp/notes_prev.md
	echo >> /tmp/notes_prev.md
	for fname in `ls $today`
	do
	    cat $today$fname >> /tmp/notes_prev.md
	    echo '$\pagebreak$' >> /tmp/notes_prev.md
	    echo >> /tmp/notes_prev.md
	done
	pandoc -o /tmp/notes_prev.pdf /tmp/notes_prev.md
	open /tmp/notes_prev.pdf
    else
	echo "`_generate_toc $today$(ls $today)`" > /tmp/notes_prev.md
	for arg in $@
	do
	    abbrvname=`ls $today | grep $arg`
	    if [[ ! $abbrvname ]]; then continue; fi
	    cat $today$abbrvname >> /tmp/notes_prev.md
	done
	pandoc -o /tmp/notes_prev.pdf /tmp/notes_prev.md
	open /tmp/notes_prev.pdf
    fi
}

preview-note() {
    pdfile=${1:0:$((${#1}-3))}.pdf
    pandoc $1 -o $pdfile
    open $pdfile
    rm $pdfile
}

notes() {
    _todays_notes
    fname="`date | awk '{ printf \"%s_%d_%d\", $2, $3, $6 }'`_$1.md"
    dub_at=""
    for i in $@; do dub_at="$dub_at $i $i "; done
    printf -v fnames "$HOME/notes/%s/`date | awk '{ printf \"%s_%d_%d\", $2, $3, $6 }'`_%s.md " $dub_at $dub_at
    printf -v notesdirs "$HOME/notes/%s/ " $@

    if [[ $# -eq 0 ]]; then
	echo 'Usage:'
        printf '\tnotes [[class_name]]: create / edit note file for todays class\n'
        printf '\tnotes today: list todays notes\n'
	printf '\tnotes preview [[class_name]]: either previews all notes or the ones in class name\n'
	return
    elif [[ $1 = 'preview' ]]; then
	_preview_notes ${@:2:${#@}}
    elif [[ $1 = 'today' ]]; then
	_show_todays_notes $notesdirs
	return
    else
	fnamelist=""
	for k in `seq 1 $(echo $notesdirs | awk -F' ' '{print NF}')`
	do
	    notesdir=`echo $notesdirs | cut -d" " -f$k`
	    fname=`echo $fnames | cut -d" " -f$k`
	    dirname=`echo $@ | cut -d" " -f$k`
	    fnamelist="$fnamelist $fname "

	    if [[ ! -d $notesdir ]]; then
		mkdir $notesdir
	    fi
	    if [[ ! -s $fname ]]; then
		echo "# $dirname Notes for `date | awk '{print $2, $3, $6}'` #" > $fname
	    fi
	
	done
	emacs $fnamelist
    fi
	 
}
