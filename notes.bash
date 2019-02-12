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

_todays_notes() {
    rm ~/notes/today/* 2>/dev/null
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
	for fname in `ls $today`
	do
	    pdfname=${fname:0:$((${#fname}-2))}pdf
	    pandoc -o $today$pdfname $today$fname
	    open $today$pdfname
	done
    else
	for arg in $@
	do
	    abbrvname=`ls $today | grep $arg`
	    pdfname=${abbrvname:0:$((${#abbrvname}-2))}pdf
	    pandoc -o $today$pdfname $today$abbrvname
	    open $today$pdfname
	done
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
		echo "# $dirname Notes for `date | awk '{print $2, $3, $6}'`" > $fname
	    fi
	
	done
	emacs $fnamelist
    fi
	 
}
