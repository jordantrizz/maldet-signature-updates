#!/usr/bin/env bash
DIR=~/git/maldet-signature-updates
DATE=$(date "+%d/%m/%Y %H:%M:%S +%Z")
TEMP=$DIR/temp
SIGS=$DIR/sigs

_echo () {
	echo $@
	echo $@ >> $DIR/check.log
}

help () {
	_echo "check.sh <start|compare|test>"
}	

getsigver () {
	CURSIGVER=$(curl -s https://cdn.rfxn.com/downloads/maldet.sigs.ver)
}

processsigfile () {
	_echo " - Downloading archive from https://cdn.rfxn.com/downloads/maldet-sigpack.tgz"
	curl -O --output $DIR/maldet-sigpack.tgz https://cdn.rfxn.com/downloads/maldet-sigpack.tgz
	_echo " - Extracting archive"
	tar -zxvf $DIR/maldet-sigpack.tgz
}

createtemp () {
	mkdir -p $TEMP/new
	mkdir -p $TEMP/current
	cp -r $SIGS/* $TEMP/current/.	
}

comparefiles () {


gitcommit () {	
	_echo " - *** Committing to git."
	git -C $DIR commit -am "Update on $DATE"
	git push		
}

checksigupdate () {
	# Check for Signature Update	
	_echo "Checking for Signature Update"

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
		_echo "Existing"
	else
		_echo " - Signature update detected"
		_echo " - Processing signature archive"
		processsigfile
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
        _echo "Starting script in $DIR on $DATE"
        checksigupdate        
}

# *** Main Loop
if [ ! $1 ]; then
        help
else
        if [ "$1" = "start" ]; then
                start
        elif [ "$1" = "compare" ]; then
                comparefiles
        elif [ "$1" = "test" ]; then
        	test
        else
        	help
        fi
fi
