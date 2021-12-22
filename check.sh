#!/usr/bin/env bash
DIR=~/git/maldet-signature-updates
DATE=$(date "+%d/%m/%Y %H:%M:%S +%Z")
TEMP=$DIR/temp
SIGS=$DIR/sigs

_echo () {
	echo "$@"
	echo "$@" >> $DIR/check.log
}

help () {
	_echo "check.sh <start|compare|test|temp>"
}	

getsigver () {
	CURSIGVER=$(curl -s https://cdn.rfxn.com/downloads/maldet.sigs.ver)
}

processfiles () {
	_echo "* Processing files"
	_echo " - Downloading archive from https://cdn.rfxn.com/downloads/maldet-sigpack.tgz"
	curl -O --output $DIR/maldet-sigpack.tgz https://cdn.rfxn.com/downloads/maldet-sigpack.tgz
	_echo " - Extracting archive"
	tar -zxvf $DIR/maldet-sigpack.tgz $TEMP/new
}

createtemp () {
	_echo "* Creating temp folders and files"
	if [ -d $TEMP ]; then
		echo " - Temp files detected deleting them"
		rm $TEMP/new/*
		rm $TEMP/current/*
	fi
	mkdir -p $TEMP/new
	mkdir -p $TEMP/current
	cp -R $SIGS/* $TEMP/current/.	
}

comparefiles () {
	_echo "* Comparing files"
	_echo " - Remove bits from *.db and rxfn.hdb"
	sed -i "s/\.[0-9]*$//g" $TEMP/new/rxfn.hdb
	sed -i "s/\.[0-9]*$//g" $TEMP/current/rxfn.hdb
	sed -i "s/\.[0-9]*$//g" $TEMP/new/*.db
	sed -i "s/\.[0-9]*$//g" $TEMP/current/*.db
	
	_echo " - Comapre rxfn.hdb"
	diff $TEMP/new/rxfn.hdb $TEMP/current/rxfn.hdb -y --suppress-common-lines
	
        _echo " - Comapre *.db"
        for f in $TEMP/new; do
		echo "Processing $TEMP/new/$f against $TEMP/current/$f"
		diff $TEMP/new/$f $TEMP/current/$f -y --suppress-common-lines
	done
	echo " - Done comparing files"
}

gitcommit () {	
	_echo " - *** Committing to git."
	git -C $DIR commit -am "Update on $DATE"
	git push		
}

checksigupdate () {
	# Check for Signature Update	
	_echo "* Checking for Signature Update"

        # First time running?
        if [ ! -f $DIR/.cursigver ]; then
                _echo " - First run, no .cursigver present, creating one"
                _echo $CURSIGVER > $DIR/.cursigver
                LASTSIGVER=$(cat $DIR/.cursigver)
        else
                LASTSIGVER=$(cat $DIR/.cursigver)
        fi
		
	if [ $CURSIGVER == $LASTSIGVER ]; then	
		_echo " - No signature update."
		_echo "Exiting"
	else
		_echo "* Signature update detected"
		_echo " - Creating temp folders and files"
		createtemp
		_echo " - Processing signature archive"
		processfiles
		_echo " - Comparing Files"
		comparefiles
		_echo " - Commiting to git"
		gitcommit
		_echo " - Updating .cursigver"
		_echo $CURSIGVER > $DIR/.cursigver
		_echo "Process complete, exiting"
	fi
}

test () {
	echo " - Test!"
}

start () {
        # Start process
        _echo "* Starting script in $DIR on $DATE"
        checksigupdate        
}

# *** Main Loop
if [ ! $1 ]; then
        help
else
        if [ "$1" = "start" ]; then start
        elif [ "$1" = "compare" ]; then comparefiles
        elif [ "$1" = "test" ]; then test
        elif [ "$1" = "temp" ]; then createtemp
        elif [ "$1" = "process" ]; then processfiles         
        else help
        fi
fi
