#!/usr/bin/env bash
DIR=~/git/maldet-signature-updates
DATE=$(date "+%d/%m/%Y %H:%M:%S +%Z")
TEMP=$DIR/temp
SIGS=$DIR/sigs

_echo () {
	echo $@
	echo $@ >> $DIR/check.log
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



gitcommit () {	
	_echo " - *** Committing to git."
	git -C $DIR commit -am "Update on $DATE"
	git push		
}

_echo "Starting script in $DIR on $DATE"

if [ ! -f $DIR/.cursigver ]; then
        _echo "First run, no .cursigver present"
        _echo "Grabbing signature file"
        getsigver
        _echo $CURSIGVER > $DIR/.cursigver
        LASTSIGVER=$(cat $DIR/.cursigver)
else
	LASTSIGVER=$(cat $DIR/.cursigver)
fi

getsigver
_echo "Current signature version $CURSIGVER"
_echo "Last signature version $LASTSIGVER"

if [ $CURSIGVER == $LASTSIGVER ]; then
	_echo "No signature update."
else
	_echo "Signatures updated."
	_echo "Processing archive"
	processsigfile
	comparefiles
	gitcommit
	_echo "Updating .cursigver"
	_echo $CURSIGVER > $DIR/.cursigver
	
fi

_echo "Exiting" 

