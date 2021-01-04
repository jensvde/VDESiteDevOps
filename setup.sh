#!/bin/bash

#Move all files
mv * /home/$USER
cd ..
sudo rm -r VDESiteDevOps

#Execute install script
sudo /home/$USER/./install.sh


