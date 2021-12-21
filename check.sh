#!/usr/bin/env bash
DIR=$(pwd)

getsigver () {
	CURSIGVER=$(curl -s https://cdn.rfxn.com/downloads/maldet.sigs.ver)
}

processsigfile () {
	curl -O https://cdn.rfxn.com/downloads/maldet-sigpack.tgz
	tar -zxvf $DIR/maldet-sigpack.tgz
		
}

echo "Starting script in $DIR"

if [ ! -f .cursigver ]; then
        echo "First run, no .cursigver present"
        echo "Grabbing signature file"
        getsigver
        echo $CURSIGVER > .cursigver
        LASTSIGVER=$(cat .cursigver)
else
	LASTSIGVER=$(cat .cursigver)
fi

getsigver
echo "Current signature version $CURSIGVER"
echo "Last signature version $LASTSIGVER"

if [ $CURSIGVER == $LASTSIGVER ]; then
	echo "No signature update."
else
	echo "Signatures updated."
	processsigfile
	
fi

echo "Exiting" 

