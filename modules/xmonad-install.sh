#!/usr/bin/env bash

echo "* Setting global USE flags in make.conf..."
echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X udev -gnome -systemd -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

# Prepare for emerge
flaggie x11-misc/lightdm-gtk-greeter +branding

echo "* Installing xmonad window manager..."
confUpdate "x11-wm/xmonad x11-wm/xmonad-contrib"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm-gtk-greeter"
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm

firstUser=$(grep "1000" /etc/passwd | cut -f 1 -d :)

echo "* Emerging urxvt and firefox for something to start off from..."
confUpdate "rxvt-unicode firefox-bin"

echo
echo "* Setting xmonad.hs..."
echo "import XMonad

main = xmonad $ defaultConfig" > /home/"$firstUser"/.xmonad/xmonad.hs

xmonad --recompile
xmonad --restart

chown "$firstUser":"$firstUser" /home/"$firstUser"/.xmonad/xmonad.hs
