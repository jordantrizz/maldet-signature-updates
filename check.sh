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
	_echo "check.sh <start|check|compare|test|temp>"
}	

getsigver () {
	CURSIGVER=$(curl -s https://cdn.rfxn.com/downloads/maldet.sigs.ver)
}

createtemp () {
	_echo "* Processing files"
	_echo " - Downloading archive from https://cdn.rfxn.com/downloads/maldet-sigpack.tgz"
	curl -O --output $DIR/maldet-sigpack.tgz https://cdn.rfxn.com/downloads/maldet-sigpack.tgz
	_echo " - Extracting archive"
	tar -zxvf $DIR/maldet-sigpack.tgz --directory $TEMP/new

	_echo "* Creating temp folders and files"
	if [ -d $TEMP ]; then
		echo " - Temp files detected deleting them"
		rm -rf $TEMP/new
		rm -rf $TEMP/current
	fi
	mkdir -p $TEMP/new
	mkdir -p $TEMP/current
	cp -R $SIGS $TEMP/current
	
        _echo " - Downloading archive from https://cdn.rfxn.com/downloads/maldet-sigpack.tgz"
        curl -O --output $DIR/maldet-sigpack.tgz https://cdn.rfxn.com/downloads/maldet-sigpack.tgz
        _echo " - Extracting archive"
        tar -zxvf $DIR/maldet-sigpack.tgz --directory $TEMP/new
}

comparefiles () {
	_echo "* Comparing files"
	_echo " - Remove bits from *.dat and rfxn.hdb"
	sed -i "s/\.[0-9]*$//g" $TEMP/new/sigs/rfxn.hdb
	sed -i "s/\.[0-9]*$//g" $TEMP/current/sigs/rfxn.hdb
	sed -i "s/\.[0-9]*$//g" $TEMP/new/sigs/*.dat
	sed -i "s/\.[0-9]*$//g" $TEMP/current/sigs/*.dat
	_echo ""
	_echo "* Comapre rfxn.hdb"
	_echo "==============="
	_echo " - Processing new/sigs/rfxn.hdb against current/sigs/rfxn.hdb"
	diff_rfxn=$(diff $TEMP/new/sigs/rfxn.hdb $TEMP/current/sigs/rfxn.hdb -y --suppress-common-lines)
	_echo "* Results *.dat"
	_echo "******************"
	_echo $diff_rfxn
	_echo "******************"
	_echo ""
        _echo "* Compare *.dat"
        _echo "==============="
        for f in $TEMP/new/sigs/*.dat; do
        	filename="${f##*/}"
		_echo " - Processing new/sigs/$filename against current/sigs/$filename"
		diff_dat=$(diff $TEMP/new/sigs/$filename $TEMP/current/sigs/$filename -y --suppress-common-lines)
		diff_dat_all+="$filename\n--\n$diff_dat \n--\n"
	done
	_echo "* Results *.dat"
        _echo "******************"
        _echo -e $diff_dat_all
        _echo "******************"
        _echo ""
	_echo " - Done comparing files"
}

gitcommit () {	
	_echo " - *** Committing to git."
	git -C $DIR commit -am "Update on $DATE
	Updated *.dat files
	===================
	$diff_dat_all
	
	Changes to rfxn.hdb
	===================
	$diff_rfxn
	"	
	git push		
}

checksigupdate () {
	# Check for Signature Update	
	_echo "* Checking for Signature Update"
	getsigver

        # First time running?
        if [ ! -f $DIR/.cursigver ]; then
                _echo " - First run, no .cursigver present, creating one"
                _echo $CURSIGVER > $DIR/.cursigver
                LASTSIGVER=$(cat $DIR/.cursigver)
        else
                LASTSIGVER=$(cat $DIR/.cursigver)
        fi
		
	if [ $CURSIGVER == $LASTSIGVER ]; then			
		_echo "- No signature update detected"
		UPDATE=no
	else
		_echo "- Signature update detected"
		UPDATE=yes
	fi
}

test () {
	echo " - Test!"
}

start () {
        # Start process
        _echo "* Starting script in $DIR on $DATE"        
        checksigupdate

        if [ $UPDATE = "yes" ]; then        	
		_echo " - Starting process!"
       		_echo " - Creating temp folders and files"
	        createtemp
        
	        _echo " - Comparing Files"
	        comparefiles
        
	        _echo " - Commiting to git"
	        gitcommit
	        _echo " - Updating .cursigver"
	        _echo $CURSIGVER > $DIR/.cursigver
	        _echo "Process complete, exiting"
	 else
	 	_echo " - Exiting..."
	 fi	 
}

# *** Main Loop
if [ ! $1 ]; then
        help
else
        if [ "$1" = "start" ]; then start
	elif [ "$1" = "check" ]; then checksigupdate
        elif [ "$1" = "compare" ]; then comparefiles
        elif [ "$1" = "test" ]; then test
        elif [ "$1" = "temp" ]; then createtemp
        elif [ "$1" = "git" ]; then gitcommit
        else help
        fi
fi
