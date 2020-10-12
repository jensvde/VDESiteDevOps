#!/bin/bash

APPNAME=VandenEynde
USERNAME=twinkeltje_peggy
GITPREFIX=VDESite
GITLINK="https://github.com/jensvde/VDESite.git /home/$USERNAME/$GITPREFIX"

sudo killall dotnet
rm -r /home/$USERNAME/$GITPREFIX
rm -r /home/$USERNAME/publish
cd /home/$USERNAME
git clone $GITLINK
cp -avrfn /home/$USERNAME/$GITPREFIX/$APPNAME/$APPNAME/bin/Release/netcoreapp3.1/publish /home/$USERNAME/publish
mv /home/$USERNAME/publish/$APPNAME.dll /home/$USERNAME/publish/$APPNAME.dll
