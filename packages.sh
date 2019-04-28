#!/bin/sh

# basic packages
pacman --noconfirm -Suy git vim htop tmux python python2

# install xorg with i3-wm
pacman --noconfirm -Suy xorg-server xorg-xinit ttf-dejavu i3-wm xterm rofi compton

echo "It is a good time to install display drivers!"