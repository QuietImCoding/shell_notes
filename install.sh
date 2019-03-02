if [[ -n $BASH_IT ]]; then
    cp notes.bash $BASH_IT/custom/
    echo "export BASH_NOTES=$(pwd)" >> $BASH_IT/lib/custom.bash
else 
    echo "It doesn't look like you have bash_it installed on your system"
    printf "Install in .bashrc? [y/n] "
    read -r resp
    if [[ $resp == "y" ]]; then
	cp notes.bash ~/.notes.bash
	cat shell_completion.bash >> ~/.notes.bash
	echo "###########################################" >> ~/.bashrc
	echo "# This enables shell notes on your system #" >> ~/.bashrc
	echo "BASH_NOTES=$(pwd)" >> ~/.bashrc
	echo "source ~/.notes.bash" >> ~/.bashrc
	echo "export BASH_NOTES" >> ~/.bashrc
	echo "###########################################" >> ~/.bashrc
	echo "Installed!"
	source ~/.bashrc
    fi
fi 

mkdir -p ~/notes/today
rm *~ 2>/dev/null

source ~/.bashrc
