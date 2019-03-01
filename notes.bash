#!/bin/bash

_print_red() { printf "\x1B[31m%s\x1B[0m" "$@"; }
_print_green() { printf "\x1B[32m%s\x1B[0m" "$@"; }
_print_bu() { printf "\x1B[1m\x1B[4m%s\x1B[0m\n" "$@"; }

# Shows a list of the notes you edited today
_show_todays_notes() {
    _print_bu "Your notes from today:"
    for dir in "$@"
    do
	dname="$(date | awk '{ printf("%s_%02d_%d", $2, $3, $6) }')"
	for fname in $(ls $dir)
	do
	    tosnip="${fname:$((${#dname}+1)):${#fname}}"
	    echo "- ${tosnip:0:$((${#tosnip}-3))}"
	done
    done
}

# Gross sed statement that gets the subject for a file and ignores its date
_get_subjects() {
    for f in "$@"
    do
	echo "$f" | sed -E 's/.*[a-zA-Z]{3}_[0-9]{1,2}_[0-9]{4}_//g' | cut -d'.' -f1
    done
}

_wrap_block() {
    # I am very scared of touching this sed command
    # If you see this comment and want to indent it consider yourself warned.
    sedcommand="/{{content}}/ {
r $1
d
}"

    sed "$sedcommand" ~/shell_notes/jinja-shell.txt |
	sed -e 's/%7B/{/g' -e 's/%7D/}/g' |
	sed -E 's/h2 id="notes-for-(.*)">/h2 id="notes-for-\1" aria-expanded="false" data-toggle="collapse" href="#\1-div">/g' | sed -E -e 's/<h2/<h2><a/g' -e 's/<\/h2>/<\/a><\/h2>/g' 

}

_push_notes() {
    curloc=$(pwd)
    _generate_toc "$(find ~/notes/ -type f -not -path '*/\.*')" > ~/notes/toc.md
    for fullname in $(find ~/notes/ -type f -not -path '*/\.*'); do
	fname="$(echo "$fullname" | rev | cut -d '/' -f1 | rev)"
	echo $fname
	outf=~/notes/.rendered/"${fname:0:$((${#fname} - 3))}.html"
	pandoc "$fullname" -o $outf 
    done
    echo "$(_wrap_block ~/notes/.rendered/toc.html)" > ~/notes/.rendered/toc.html
    rm ~/notes/toc.md
    cd ~/notes/.rendered || return
    git add ./*
    git commit -m "Pushed on $(date)"
    git push
    cd "$curloc" || return
}

_register_notes() {
    printf "Which ssh key do you want to use?  "
    read -r keyfile
    remote=$(curl https://bashnotes.com/tokencheck -X POST \
	       -F "user-token=$1" \
	       -F "ssh-key=$(cat ~/.ssh/"$keyfile".pub)")
    if echo $remote | grep -q 'BAD'; then return; fi
    git init ~/notes/.rendered
    curloc=$(pwd)
    cd ~/notes/.rendered || return
    echo "Notes" > placeholder.txt && git add placeholder.txt
    git commit -m "Placeholder commit"
    git remote add origin "$remote"
    git push --set-upstream origin master
    git rm placeholder.txt && git commit -m "Placeholder removed!"
    _push_notes
    cd "$curloc" || return
}

_generate_toc() {
    echo "# Table of Contents #"
    for subj in $(_get_subjects "$@" | sort | uniq)
    do
	echo "## Notes for $subj ##"
	echo "<div class=\"collapse\" id=\"${subj}-div\">"
	echo
	# Grep -o only outputs matching parts... who knew? not me
	for f in $(echo "$@" |
		       grep  -o -E "([^[:space:]]*${subj}.md[^[:space:]]*)" | sort)
	do
	    cur_inc=1
	    # Cat the file and get semicolon-delimited list of headers
	    headers="$(awk '$1 ~ "#+" { $1="";$NF="";printf( "%s;", $0 )}' < "$f")"
	    # Loop over delimited header list
	    for i in $(seq 1 "$(awk -F";" '{print NF-1}' <<< "$headers")")
	    do
		# Get ith header
		# This statement is slowly becoming the bane of my existence
		h="$(echo "$headers" | cut -d';' -f"$i" | sed -e "s/'/\\\'/g" -e 's/[():]//g' | xargs)"
		# Convert to id by lowercasing and adding dashes
		id="$(echo "$h" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
		if echo "$h" | grep -q 'Notes for'; then
		    datehdr="$(echo "$h" | sed -E 's/.*Notes for //g')"
		    und_hdr="$(echo $datehdr | tr ' ' '_')"
		    echo "### [$datehdr](/{{username}}/$subj/$und_hdr) ###"

		else
		    echo "$((cur_inc)). [$h](#$id)"
		fi
	    done

	    cur_inc=$((cur_inc + i))
	    echo
	done
	echo "</div>"
    done
    #echo '$\pagebreak$'
}



_todays_notes() {
    rm ~/notes/today/* 2>/dev/null
    rm "$(find ~/notes/ | grep '~')" 2>/dev/null
    dname="$(date | awk '{ printf("%s_%02d_%d", $2, $3, $6) }')"
    for fname in $(find ~/notes | grep '^[^#].*md$')
    do
	if [[ $fname = *$dname* ]]; then
	    cp "$fname" ~/notes/today/
	fi
    done
}

# NOTE: first argument is interpreted as a path and gets shifted out
_preview_notes() {
    # Append path to files
    path=$1
    shift 1
    listing="$(for note in "$@"; do echo "$path$note"; done)"
    _generate_toc "$listing" > /tmp/notes_prev.md
    echo >> /tmp/notes_prev.md
    for fname in $listing
    do
	echo "$fname"
	{   cat "$fname", 
	    echo '$\pagebreak$', 
	    echo
	} >> /tmp/notes_prev.md
    done
    pandoc -o /tmp/notes_prev.pdf /tmp/notes_prev.md
    open /tmp/notes_prev.pdf
}

_upgrade_notes() {
    echo "Upgrading to latest shell-notes version..."
    cp ~/shell_notes/notes.bash "$BASH_IT"/custom/
    cp ~/shell_notes/shell_completion.bash "$BASH_IT"/completion/custom.completion.bash
    shit reload
}

_search_notes() {
    query=$(echo "(($@).*){$((${#@} / 2 + 1)),}" | sed -E 's/ +/\|/g')
    notelocs=$(grep -iRE "$query" ~/notes/ | awk -F':' '{print $1}')
    notecontent=$(grep -iRE "$query" ~/notes/ | sed -E 's:\*:\\\*:g' | awk -F':' '{printf("%s:", $2)}')
    ind=1
    _print_bu "Search Results:\n"
    for k in $notelocs
    do
	thiscont=$(echo "$notecontent" | cut -d':' -f$ind)
	subj=$(_get_subjects "$k")
	fdate=$(echo "$k" | cut -d'_' -f1,2,3 | grep -Eo '\w*_\w*' | sed 's/_/ /g')
	printf " - "
	_print_red "$subj "
	_print_green "on $fdate "
	echo "$thiscont"
	((ind++))
    done
}

_preview_todays_notes() {
    today=~/notes/today/
    if [[ $# -eq 0 ]]; then
	_preview_notes $today "$(ls $today)" 
    else
	# Generate grep -e's 
	exprs="$(for i in "$@"; do echo "-e $i"; done )"
	_preview_notes $today "$(ls $today | grep "$exprs")"
    fi
}



notes() {
    _todays_notes
    fname="$(date | awk '{ printf("%s_%02d_%d", $2, $3, $6) }')_$1.md"

    # What happens here is TRULY disgusting
    dub_at=""
    for i in "$@"; do dub_at="$dub_at $i $i "; done
    printf -v fnames "$HOME/notes/%s/$(date | awk '{ printf("%s_%02d_%d", $2, $3, $6) }')_%s.md " $dub_at $dub_at
    printf -v notesdirs "$HOME/notes/%s/ " "$@"

    # Print usage message if no args
    if [[ $# -eq 0 ]]; then
	echo 'Usage:'
        printf '\tnotes [[class_name]]: create / edit note file for todays class\n'
        printf '\tnotes today: list todays notes\n'
	printf '\tnotes preview [[class_name]]: either previews all notes or the ones in class name\n'
	printf '\tnotes update: update notes from git local repo\n'
	return
    elif [[ $1 = 'preview' ]]; then
	# Pass rest of arguments to _preview_todays_notes
	_preview_todays_notes "${@:2:${#@}}"
    elif [[ $1 = 'today' ]]; then
	# List notes
	_show_todays_notes "$notesdirs"
	return
    elif [[ $1 = 'register' ]]; then
	_register_notes "$2"
	return
    elif [[ $1 = 'push' ]]; then
	_push_notes
	return
    elif [[ $1 = 'update' ]]; then
	_upgrade_notes
	return
    elif [[ $1 = 'search' ]]; then
	_search_notes "$2"
	return
    else
	fnamelist=""
	for k in $(seq 1 "$(echo "$notesdirs" | awk -F' ' '{print NF}')")
	do
	    notesdir=$(echo "$notesdirs" | cut -d" " -f"$k")
	    fname=$(echo "$fnames" | cut -d" " -f"$k")
	    
	    dirname=$(echo "$@" | cut -d" " -f"$k")
	    fnamelist="$fnamelist $fname "

	    if [[ ! -d $notesdir ]]; then
		mkdir "$notesdir"
	    fi
	    if [[ ! -s $fname ]]; then
		echo "# $dirname Notes for $(date | awk '{ printf("%s_%02d_%d", $2, $3, $6) }') #" > "$fname"
	    fi
	    echo "$fname"
	done
	edit "$fname"
    fi
	 
}
