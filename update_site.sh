#!/bin/bash

APPNAME=Winkeltje
APPLOWERNAME=winkeltje
USERNAME=jens
GITPREFIX=Winkeltje
GITLINK="https://github.com/jensvde/$GITPREFIX /home/$USERNAME/$GITPREFIX"

cd /home/$USERNAME
sudo killall dotnet
sudo systemctl stop kestrel-$APPLOWERNAME.service
sudo rm -r /home/$USERNAME/$GITPREFIX
sudo rm -r /home/$USERNAME/publish
git clone $GITLINK 

#For debug
#cp -avrfn /home/$USERNAME/$GITPREFIX/$APPNAME/bin/Debug/netcoreapp3.1 /home/$USERNAME/publish

#For release:
cp -avrfn /home/$USERNAME/$GITPREFIX/$APPNAME/bin/Release/netcoreapp3.1/publish /home/$USERNAME/publish

sudo systemctl start kestrel-$APPLOWERNAME.service
sudo systemctl status kestrel-$APPLOWERNAME.service
