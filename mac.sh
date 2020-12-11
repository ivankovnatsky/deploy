#!/usr/bin/env bash

# https://github.com/mathiasbynens/dotfiles/blob/main/.macos

set -xe

osascript -e 'tell application "System Preferences" to quit'

sudo nvram SystemAudioVolume=" "

comp_name="Mac"

sudo scutil --set ComputerName "${comp_name}"
sudo scutil --set HostName "${comp_name}"
sudo scutil --set LocalHostName "${comp_name}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${comp_name}"

# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# make sure dev tools are installed
xcode-select --install

# brew; will install git here also
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

gem install iStats

pip3 install tmuxp

brew services start syncthing
