#!/bin/bash

function system_update {
  # Update OS
  lsb_release -a

  echo -e "\n--- Ubuntu updating ---"
  sudo apt-get update        # Fetches the list of available updates
  sudo apt-get upgrade       # Strictly upgrades the current packages
  sudo apt-get dist-upgrade  # Installs updates (new ones), will not upgrade to a new Ubuntu release
  sudo apt-get autoremove    # Remove any install packages
  echo Update complete
  
  echo -e "\n--- Ubuntu version info now: ---"
  lsb_release -a
}

function inc_custom_bash {
    # add custom bash in to .profile
    if [ -e "$HOME/.bash_custom" ]; then
        echo ""                                         >> $HOME/.profile
        echo "# include .bash_custom if it exists"      >> $HOME/.profile
        echo "if [ -f \"$HOME/.bash_custom\" ]; then"   >> $HOME/.profile
        echo "    . \"$HOME/.bash_custom\""             >> $HOME/.profile
        echo "fi"                                       >> $HOME/.profile
    fi
}

echo -e "\n--- system.sh imported ---"