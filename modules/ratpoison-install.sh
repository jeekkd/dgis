#!/usr/bin/env bash

echo "* Setting global USE flags in make.conf..."
echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X dbus udev -gnome -systemd -minimal alsa pam tcpd ssl\"" >> /etc/portage/make.conf

# Prepare for emerge
flaggie x11-wm/ratpoison +xft
flaggie x11-wm/ratpoison +sloppy
flaggie rxvt-unicode +xft
flaggie rxvt-unicode +iso14755
flaggie x11-misc/lightdm-gtk-greeter +branding

echo "* Installing Ratpoison window manager..."
confUpdate "x11-wm/ratpoison"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm-gtk-greeter"
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm

firstUser=$(grep "1000" /etc/passwd | cut -f 1 -d :)

echo "* Emerging urxvt and firefox for something to start off from..."
confUpdate "rxvt-unicode firefox-bin"

echo
echo "* Setting .ratpoisonrc..."
echo "# Add key bindings:
bind c exec /usr/bin/urxvt
bind f exec /usr/bin/firefox-bin

# What programs should be ran on start up?
exec /usr/bin/numlockx

# Initiate here the number of desired workspaces:
exec /usr/bin/rpws init 4 -k" > /home/"$firstUser"/.ratpoisonrc

chown "$firstUser":"$firstUser" /home/"$firstUser"/.ratpoisonrc
