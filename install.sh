if [[ -n $BASH_IT ]]; then
    cp notes.bash $BASH_IT/custom/
else 
    echo "It doesn't look like you have bash_it installed on your system"
    printf "Install in .bashrc? [y/n]"
    read -r resp
    if [[ resp == "y" ]]; then
	cp notes.bash ~/.notes.bash
	echo "source ~/.notes.bash" >> ~/.bashrc
    fi
fi 

mkdir -p ~/notes/today
rm *~ 2>/dev/null
