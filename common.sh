#!/usr/bin/env bash

set -xe

ssh-keygen -t ed25519 -C "email@example.com"
gpg --full-gen-key
gpg --armor --export-options export-minimal --export gpg "EXAMPLE"

git config --global user.name
git config --global user.email
git config --global user.singingkey

# for win
git config --global core.autocrlf true

# clone dotfiles
git clone <url>/dotfiles /tmp/dotfiles
cd /tmp/dotfiles || exit
mv * ~/
mv .[a-zA-Z0-9_]* ~/
cd ~/
git remote set-url origin git@<url>/dotfiles.git

# python
python3 -m pip install aws-mfa

# tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

# tgenv
git clone https://github.com/cunymatthieu/tgenv.git ~/.tgenv
export PATH="$HOME/.tgenv/bin:$PATH"
