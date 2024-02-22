#!/bin/bash

if [ ! -d ~/Documents/Xcode/WiredClient/"Wired Client.app" ]; then
	echo "App nicht in den Ordner kopiert. Abbruch."
	exit 1
fi

rm -r /Users/luigi/Library/Caches/Sparkle_generate_appcast/*

    rm ~/Documents/Xcode/WiredClient/app/appcast.xml
    cp ~/Documents/Xcode/WiredClient/wiredclient.html ~/Documents/Xcode/WiredClient/app/
    ditto -c -k --sequesterRsrc --keepParent ~/Documents/Xcode/WiredClient/"Wired Client.app" ~/Documents/Xcode/WiredClient/app/wiredclient.zip

    /Applications/Sparkle/bin/generate_appcast ~/Documents/Xcode/WiredClient/app/

    #cd ~/Documents/Xcode/WiredClient
    #git add app/appcast.xml
    #git add app/wiredclient.html
    #git add app/wiredclient.zip

    #git commit -m "App geupdated"
    #git push origin main


#rm -r ~/Documents/Xcode/WiredClient/"Wired Client.app"


