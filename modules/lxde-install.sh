#!/usr/bin/env bash

echo " " >> /etc/portage/make.conf
echo "# Global USE flag declaration" >> /etc/portage/make.conf
echo "USE=\"X gtk -kde -minimal dbus jpeg lock session startup-notification udev -systemd -gnome alsa bindist infinality\"" >> /etc/portage/make.conf

# Prepare for emerge
flaggie x11-wm/openbox +branding
flaggie lxde-base/lxsession +upower
flaggie x11-libs/libfm +udisks
flaggie lxde-base/lxpanel +wifi
flaggie x11-misc/lightdm-gtk-greeter +branding

echo "* Installing LXDE Desktop Environment..."
confUpdate "lxde-base/lxde-meta app-editors/leafpad"

echo
echo "* Display manager installation.."
confUpdate "x11-misc/lightdm-gtk-greeter"
sed -i 's/xdm/lightdm/g' /etc/conf.d/xdm

echo "* Emerging firefox for something to start off from..."
confUpdate "firefox-bin"
