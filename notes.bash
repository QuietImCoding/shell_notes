#!/bin/bash
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
    for subj in `_get_subjects $@ | uniq`
    do
	echo "## Notes for $subj ##"
	echo
	# Grep -o only outputs matching parts... who knew? not me
	for f in `echo $@ | grep  -o -E "([^[:space:]]*${subj}.md[^[:space:]]*)"`
	do
	    cur_inc=0
	    # Cat the file and get semicolon-delimited list of headers
	    headers="$(cat $f | awk '$1 ~ "#+" { $1="";$NF=""; printf( "%s;", $0 )}')"
	    # Loop over delimited header list
	    for i in $(seq 1 `awk -F";" '{print NF-1}' <<< "$headers"`)
	    do
		# Get ith header
		h="`echo $headers | cut -d';' -f"$i" | xargs`"
		# Convert to id by lowercasing and adding dashes
		id="$(echo $h | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
		if echo $h | grep -q 'Notes for'; then
		    datehdr="`echo $h | sed -E 's/.*Notes for //g'`"
		    echo "### [$datehdr](#$id) ###"
		else
		    echo "$((cur_inc + i)). [$h](#$id)"
		fi
	    done
	    cur_inc=$((cur_inc + i))
	    echo
	done
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

# NOTE: first argument is interpreted as a path and gets shifted out
_preview_notes() {
    # Append path to files
    path=$1
    shift 1
    listing="$(for note in $@; do echo $path$note; done)"
    echo "`_generate_toc $listing`" > /tmp/notes_prev.md
    echo >> /tmp/notes_prev.md
    for fname in $listing
    do
	echo $fname
	cat $fname >> /tmp/notes_prev.md
	echo '$\pagebreak$' >> /tmp/notes_prev.md
	echo >> /tmp/notes_prev.md
    done
    pandoc -o /tmp/notes_prev.pdf /tmp/notes_prev.md
    open /tmp/notes_prev.pdf
}

_preview_todays_notes() {
    today=~/notes/today/
    if [[ $# -eq 0 ]]; then
	_preview_notes $today "$(ls $today)" 
    else
	# Generate grep -e's 
	exprs="$(for i in $@; do echo "-e $i"; done )"
	_preview-notes $today "$(ls $today | grep $exprs)"
    fi
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
	# Pass rest of arguments to _preview_todays_notes
	_preview_todays_notes ${@:2:${#@}}
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
